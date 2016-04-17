   #include <stdio.h>
 #include <cuda.h>
 #include <time.h>
 #define EXPO 3


__global__ void RecursiveDoublingKernel(int variableSize, int step,int blockRow, int blockColumn,float* deviceY,float* deviceM,int evenOrOddFlag,float deviceA,float* deviceB,float* deviceC, float *deviceD)
{
	//we weill do something like y(i+1)=my(i)+b
	int bx=blockIdx.x;
	int by=blockIdx.y;
	int tx=threadIdx.x;
	int ty=threadIdx.y;

	int processIndex=tx;
	printf("%d ",tx);

    printf("%f,%f,%f \n",deviceY[0],deviceY[1],deviceY[2]);
    printf("%f,%f,%f \n",deviceM[0],deviceM[1],deviceM[2]);
    

	//so M and Y will be divided into two part, the first part store the old value
	//the second half part store the updated value

	int halfSize=variableSize;
	//teh start index of the second part will be halfsize;
    //so if evenOrOddFlag is Odd, the new value will be stored in the second half,
    //otherwise it will be stored in the first half. 
    int secondhalfHelper=halfSize+step+processIndex;
    printf("second half helper is: %d \n",secondhalfHelper);

    //be careful that 1-step the old value still need to be copied to the current value,since the new value will start calculated at step+1

    if(evenOrOddFlag%2==1)
    {
    	printf("does this ever got run?");
      deviceY[secondhalfHelper]=deviceY[secondhalfHelper-halfSize]+deviceM[secondhalfHelper-halfSize]*deviceY[processIndex];
      deviceM[secondhalfHelper]=deviceM[secondhalfHelper-halfSize]*deviceM[processIndex];
      //copy it once here
      if(tx==0&&ty==0)
      {
      	for(int i=0;i<step;i++)
      	{
          deviceY[i+halfSize]=deviceY[i];
          deviceM[i+halfSize]=deviceM[i];
      	}
      }
    }
    else
    {
       
       printf("this should not run \n");//so will store the new value in the first part
      deviceY[secondhalfHelper-halfSize]=deviceY[secondhalfHelper]+deviceM[secondhalfHelper]*deviceY[halfSize+processIndex];
      deviceM[secondhalfHelper-halfSize]=deviceM[secondhalfHelper]*deviceM[halfSize+processIndex];

       if(tx==0&&ty==0) //just need to copy once, so the other processors allow to idle at thsi time
      {
      	for(int i=0;i<step;i++)
      	{
          deviceY[i]=deviceY[i+halfSize];
          deviceM[i+halfSize]=deviceM[i];
      	}
      }
    }
  


    __syncthreads();
}

__global__ void MatrixVersionRecursiveDoubling(int variableSize, int step,int blockRow, int blockColumn,float* deviceYForW,float* deviceMForW,int evenOrOddFlag,float* deviceA, float* deviceB, float* deviceC, float* deviceD)
{
  //so right now just use grid (1,1) if time allow will implment other grid size
  	int bx=blockIdx.x;
	int by=blockIdx.y;
	int tx=threadIdx.x;
	int ty=threadIdx.y;

	int processId=tx; //this is only for the this particluar grid and block setup
    
    int halfSizeY=variableSize;
    int halfSizeM=2*variableSize;
/*
    int secondhalfHelper=halfSize+step+2*processIndex; //this need to multiply 2, different from non-matrix version
    int secondhalfHelper1=halfSize+step+4*processIndex;*/

    int indexHelperY=halfSizeY+2*step+2*processId;
    int indexHelperM=halfSizeM+4*step+4*processId;

    if(evenOrOddFlag%2==1)
    {
    	//update M and Y here
    	deviceYForW[indexHelperY]=deviceYForW[indexHelperY-halfSizeY]+deviceMForW[indexHelperM-halfSizeM]*deviceYForW[2*processId]+deviceMForW[indexHelperM-halfSizeM+1]*deviceYForW[2*processId+1];
    	deviceYForW[indexHelperY+1]=deviceYForW[indexHelperY-halfSizeY+1]+deviceMForW[indexHelperM-halfSizeM+2]*deviceYForW[2*processId]+deviceMForW[indexHelperM-halfSizeM+3]*deviceYForW[2*processId+1];

        deviceMForW[indexHelperM]=deviceMForW[4*step+4*processId]*deviceMForW[4*processId]+deviceMForW[4*step+4*processId+1]*deviceMForW[4*processId+2];
        deviceMForW[indexHelperM+1]=deviceMForW[4*step+4*processId]*deviceMForW[4*processId+1]+deviceMForW[4*step+4*processId+1]*deviceMForW[4*processId+3];
        deviceMForW[indexHelperM+2]=deviceMForW[4*step+4*processId+2]*deviceMForW[4*processId]+deviceMForW[4*step+4*processId+3]*deviceMForW[4*processId+2];
        deviceMForW[indexHelperM+3]=deviceMForW[4*step+4*processId+2]*deviceMForW[4*processId+1]+deviceMForW[4*step+4*processId+3]*deviceMForW[4*processId+3];

        //now need to copy 1-- step old value to new value just need to copy once for each step
        for(int i=0;i<step;i++)
        {
        	deviceYForW[halfSizeY+2*i]=deviceYForW[2*i];
        	deviceYForW[halfSizeY+2*i+1]=deviceYForW[2*i+1];

        	deviceMForW[halfSizeM+4*i]=deviceMForW[4*i];
        	deviceMForW[halfSizeM+4*i+1]=deviceMForW[4*i+1];
        	deviceMForW[halfSizeM+4*i+2]=deviceMForW[4*i+2];
        	deviceMForW[halfSizeM+4*i+3]=deviceMForW[4*i+3];
        }
    }
    else
    {
        deviceYForW[indexHelperY-halfSizeY]=deviceYForW[indexHelperY]+deviceMForW[indexHelperM]*deviceYForW[2*processId+halfSizeY]+deviceMForW[indexHelperM+1]*deviceYForW[2*processId+1+halfSizeY];
    	deviceYForW[indexHelperY-halfSizeY+1]=deviceYForW[indexHelperY+1]+deviceMForW[indexHelperM+2]*deviceYForW[2*processId+halfSizeY]+deviceMForW[indexHelperM+3]*deviceYForW[2*processId+1+halfSizeY];

        deviceMForW[indexHelperM-halfSizeM]=deviceMForW[4*step+4*processId+halfSizeM]*deviceMForW[4*processId+halfSizeM]+deviceMForW[4*step+4*processId+1+halfSizeM]*deviceMForW[4*processId+2+halfSizeM];
        deviceMForW[indexHelperM+1-halfSizeM]=deviceMForW[4*step+4*processId+halfSizeM]*deviceMForW[4*processId+1+halfSizeM]+deviceMForW[4*step+4*processId+1+halfSizeM]*deviceMForW[4*processId+3+halfSizeM];
        deviceMForW[indexHelperM+2-halfSizeM]=deviceMForW[4*step+4*processId+2+halfSizeM]*deviceMForW[4*processId+halfSizeM]+deviceMForW[4*step+4*processId+3+halfSizeM]*deviceMForW[4*processId+2+halfSizeM];
        deviceMForW[indexHelperM+3-halfSizeM]=deviceMForW[4*step+4*processId+2+halfSizeM]*deviceMForW[4*processId+1+halfSizeM]+deviceMForW[4*step+4*processId+3+halfSizeM]*deviceMForW[4*processId+3+halfSizeM];

        //now need to copy 1-- step old value to new value just need to copy once for each step
        for(int i=0;i<step;i++)
        {
        	deviceYForW[2*i]=deviceYForW[2*i+halfSizeY];
        	deviceYForW[2*i+1]=deviceYForW[2*i+1+halfSizeY];

        	deviceMForW[4*i]=deviceMForW[4*i+halfSizeM];
        	deviceMForW[4*i+1]=deviceMForW[4*i+1+halfSizeM];
        	deviceMForW[4*i+2]=deviceMForW[4*i+2+halfSizeM];
        	deviceMForW[4*i+3]=deviceMForW[4*i+3+halfSizeM];
        }

    }


}

int main()
{
/* float* M;
 float* Y;
 int variableSize=10;
 int variableSpace=2*variableSize*sizeof(float);*/
   //make it double size since it run in parallel so you want to keep all the previous version
/* M=(float*)malloc(variableSpace);
 Y=(float*)malloc(variableSpace); */

/* M[0]=1;
 Y[0]=1;*/

 int m=pow(2,EXPO)-1; 
 int b=1;
 int a=0;
 float delta=(b-a)*1.0/(m+1.0);

//store teh metrix that is to be LU decomposited
 float *A;
 float *B;
 float *C;
 float *D;


	int chunkLength=m;
	int chunkSize=chunkLength*sizeof(float);
	A=(float*)malloc(chunkSize);
	B=(float*)malloc(chunkSize);
	C=(float*)malloc(chunkSize);
	D=(float*)malloc(chunkSize);

	 A[0]=0;
        //int vectorLength=EXPO*m;
     
        for(int i=1;i<m;i++)
        {
            A[i]=1-delta*delta*0.5*(i+1);
        }
        //else will be 0
      /*  for(int i=m;i<chunkLength;i++)
        {
          A[i]=0;
        }*/

        for(int i=0;i<m;i++)
        {
            B[i]=-2+delta*delta*1.0;
        }
      /*    for(int i=m;i<chunkLength;i++)
        {
          B[i]=0;
        }*/

        C[m-1]=0;
        for(int i=0;i<m-1;i++)
        {
            C[i]=1+0.5*delta*delta*(i+1);
        }
     /*   for(int i=m;i<chunkLength;i++)
        {
          C[i]=0;
        }*/


       /* D[0]=2*delta*delta*delta+0.5*delta*delta-1;*/
        for(int i=0;i<m-1;i++)
        {
            D[i]=2*(i+1)*pow(delta,3);
        }
        D[m-1]=2*m*delta*delta*delta-1+3.5*delta*delta;
      /*  for(int i=m;i<chunkLength;i++)
        {
          D[i]=0;
        }*/

       float *deviceA, *deviceB, *deviceC, *deviceD;
        cudaMalloc((void**)&deviceA,chunkSize);
        cudaMalloc((void**)&deviceB,chunkSize);
        cudaMalloc((void**)&deviceC,chunkSize);
        cudaMalloc((void**)&deviceD,chunkSize);     
       //copy the host vector to device.
        cudaMemcpy(deviceA,A,chunkSize,cudaMemcpyHostToDevice);
        cudaMemcpy(deviceB,B,chunkSize,cudaMemcpyHostToDevice);
        cudaMemcpy(deviceC,C,chunkSize,cudaMemcpyHostToDevice);
        cudaMemcpy(deviceD,D,chunkSize,cudaMemcpyHostToDevice);

        clock_t begin,end;
        begin=clock();

     //start the code to calculate the w with recursive doubling applied to matrix
      //so we need 2*2*(N-1) for both YforW and 2*4*(N-1) for MforW , the size N should be equal to m here
     float *MforW, *YforW;
     

     int MforWLength=4*(m-1);
     int YforWLength=2*(m-1);
     int MforWSize=2*MforWLength*sizeof(float);
     int YforWSize=2*YforWLength*sizeof(float);
     MforW=(float*)malloc(MforWSize);
     YforW=(float*)malloc(YforWSize);

     //the first step of recursive doubling, initialize Y and M;
     YforW[0]=1;
     YforW[1]=B[0]/(C[0]*1.0);
     //the other should be 0 since V(I)=A[I]V[I-1]+0
     for(int i=2;i<YforWLength;i++)
     {
     	YforW[i]=0;
     }
     //the first one for M should be[1,0,0,1]
     MforW[0]=1;
     MforW[1]=0;
     MforW[2]=0;
     MforW[3]=1;
     for(int i=4;i<MforWLength;i=i+4)
     {
     	MforW[i]=0;
     	MforW[i+1]=1;
     	MforW[i+2]=-1.0*A[i/4]/C[i/4];
     	MforW[i+3]=1.0*B[i/4]/C[i/4];
     }

     float *deviceMforW, *deviceYforW;
     cudaMalloc((void**)&deviceMforW,MforWSize);
     cudaMalloc((void**)&deviceYforW,YforWSize);

     cudaMemcpy(deviceMforW,MforW,MforWSize,cudaMemcpyHostToDevice);
     cudaMemcpy(deviceYforW,YforW,YforWSize,cudaMemcpyHostToDevice);

   
   int step=1;
   int evenOrOddFlag=0;

  do {
  	 //each time needs N-Step processors
  	
  	  evenOrOddFlag=evenOrOddFlag+1;
  	  dim3 dimGrid(1,1);
  	  int blockRow=1;
  	  int blockColumn=(m-1)-step;
  	  dim3 dimBlock(blockColumn,blockRow);
  	  //variableSIZE should be half size y
  	  MatrixVersionRecursiveDoubling<<<dimGrid,dimBlock>>>(YforWLength,step,blockRow,blockColumn,deviceYforW,deviceMforW,evenOrOddFlag,deviceA,deviceB,deviceC,deviceD);
        step=step+step;
    
   }while( step <= YforWLength/2);

   //so if evenOrOddFlag is odd, it means that the latest value will be second half,
   //otherwise it will be in the first half
   cudaMemcpy(MforW,deviceMforW,MforWSize,cudaMemcpyDeviceToHost);
   cudaMemcpy(YforW,deviceYforW,YforWSize,cudaMemcpyDeviceToHost);


/*M[0]=1;
Y[0]=1;

 for(int i=1;i<variableSize;i++)
 {
 	M[i]=2;
 	Y[i]=3;
 }
 float *deviceM, *deviceY;
 cudaMalloc((void**)&deviceM,variableSpace);
 cudaMalloc((void**)&deviceY,variableSpace);

 cudaMemcpy(deviceM,M,variableSpace,cudaMemcpyHostToDevice);
 cudaMemcpy(deviceY,Y,variableSpace,cudaMemcpyHostToDevice);

   
   int step=1;
   int evenOrOddFlag=0;

  do {
  	 //each time needs N-Step processors
  	
  	  evenOrOddFlag=evenOrOddFlag+1;
  	  dim3 dimGrid(1,1);
  	  int blockRow=1;
  	  int blockColumn=variableSize-step;
  	  dim3 dimBlock(blockColumn,blockRow);
  	  RecursiveDoublingKernel<<<dimGrid,dimBlock>>>(variableSize,step,blockRow,blockColumn,deviceY,deviceM,evenOrOddFlag);
        step=step+step;
      
    
   }while( step <= variableSize);

   //so if evenOrOddFlag is odd, it means that the latest value will be second half,
   //otherwise it will be in the first half
   cudaMemcpy(M,deviceM,variableSpace,cudaMemcpyDeviceToHost);
   cudaMemcpy(Y,deviceY,variableSpace,cudaMemcpyDeviceToHost);*/
/*   printf("solution is here: \n");
   if(evenOrOddFlag%2==0)
   {
     for(int i=0;i<variableSize;i++)
     {
     	printf("%f \n",Y[i]);
     }
   }
   else
   {
   	  for(int i=0;i<variableSize;i++)
     {
     	printf("%f \n",Y[i+variableSize]);
     }
   }*/

      printf("solution is here: \n");
   if(evenOrOddFlag%2==0)
   {
     for(int i=0;i<YforWLength;i++)
     {
     	printf("%f \n",YforW[i]);
     }
   }
   else
   {
   	  for(int i=0;i<YforWLength;i++)
     {
     	printf("%f \n",YforW[i+YforWLength]);
     }
   }
      double time_spent;
      end=clock();
      time_spent=(double)(end-begin)/CLOCKS_PER_SEC;
      printf("\n time used to calculate this is :%f seconds \n",time_spent);
        cudaFree(deviceA);
        cudaFree(deviceB);
        cudaFree(deviceC);
        cudaFree(deviceD);
        cudaFree(deviceMforW);
        cudaFree(deviceYforW);
       
        free(A);
        free(B);
        free(C);
        free(D);
        free(MforW);
        free(YforW);

  return 0;
}

