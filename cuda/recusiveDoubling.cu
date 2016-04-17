   #include <stdio.h>
 #include <cuda.h>
 #include <time.h>
 #define VARCOUNT 3


__global__ void RecursiveDoublingKernel(int variableSize, int step,int blcokRow, int blockColumn,float* deviceY,float* deviceM,int evenOrOddFlag)
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
          deviceM[i]=deviceM[i+halfSize];
      	}
      }
    }
  


    __syncthreads();
}

int main()
{
 float* M;
 float* Y;
 int variableSize=10;
 int variableSpace=2*variableSize*sizeof(float);
   //make it double size since it run in parallel so you want to keep all the previous version
 M=(float*)malloc(variableSpace);
 Y=(float*)malloc(variableSpace); 

 M[0]=1;
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
   cudaMemcpy(Y,deviceY,variableSpace,cudaMemcpyDeviceToHost);
   printf("solution is here: \n");
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
   }
  /*   if(evenOrOddFlag%2==0)
   {
     for(int i=0;i<variableSize*2;i++)
     {
     	printf("%f \n",M[i]);
     }
   }
   else
   {
   	  for(int i=0;i<variableSize*2;i++)
     {
     	printf("%f \n",M[i+variableSize]);
     }
   }*/
  return 0;
}

