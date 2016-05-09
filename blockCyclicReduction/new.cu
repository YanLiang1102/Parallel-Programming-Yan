     #include <stdio.h>
    #include <cuda.h>
    #include <time.h>
    #include <math.h>
    //#include <unistd.h>
    #define EXPO 2 //so [0,1] will be break into 2^6 intervals 64*64
    #define PI 3.14159265

    __global__ void CalculateTheD(int step,float* deviceB, float* deviceC, float* deviceD, float* deviceX, float* devicenewB, float* devicenewC)
    {
       int blocksize=16;
       int gridsize=gridDim.x; //this will always be 1
       // int gridsize2=gridDim.x;
       // printf("gridsize: %d %d\n", gridsize,gridsize2);
       // __device__ bool myGlobalFlag=true;
       
        int bx=blockIdx.x;
        int by=blockIdx.y;
        int tx=threadIdx.x;
        int ty=threadIdx.y;
        
        int blocktotal=blocksize*blocksize;
        int temp1=by*gridsize+bx;
        int temp2=ty*blocksize+tx;

       int ind=temp1*blocktotal+temp2;

      int m=(int)pow(2.0,EXPO*1.0)-1;
      /*int column=threadIdx.x;
      int row=threadIdx.y;*/
      int row=ind/m;
      int column=ind%m;

      int iloopstep=(int)pow(2.0,(EXPO-step)*1.0)-1;
      int h=(int)pow(2.0,(step-1)*1.0);
      int multiplier=(int)pow(2.0,step*1.0);
      int countHelper1=(int)pow(2.0,EXPO+1.0);
      int countHelper2=(int)pow(2.0,EXPO-step+2);

      float* oldB;
      float* oldC;
 

      float* newB;
      float* newC;
      //float* newD;
    
     //this is to exchange which hold the previous value which hold the current value
      if(step%2==0)
      {
      	oldB=devicenewB;
      	oldC=devicenewC;
      	/*oldD=devicenewD;*/

      	newB=deviceB;
      	newC=deviceC;
     /* 	newD=deviceD;*/
      }
      else
      {
      	oldB=deviceB;
      	oldC=deviceC;
      /*	oldD=deviceD;*/
        
        newB=devicenewB;
        newC=devicenewC;
  /*      newD=devicenewD;*/
      }

      //use the device value as old value and store the updated one in to the new value
      if(ind<m*m) //so only the first 63 threads do work and the other one is hanging there
      {
		    float sumBB=0.0;
		    for(int k=0;k<m;k++)
		    {
		      sumBB=sumBB+oldB[row*m+k]*oldB[k*m+column];
		    }
		    float sumCC=0.0;
		    for(int k=0;k<m;k++)
		    {
		      sumCC=sumCC+oldC[row*m+k]*oldC[k*m+column];
		    }

		    //based on formula (5.4.2.15) on book
		    newB[row*m+column]=2*sumCC-sumBB;
		    newC[row*m+column]=sumCC;

		    //now calculate the new d and it needs to loop through i in each block
		    //look at the third formula on 5.4.2.15 on book
		    ///D[ith BLOCK][j thSTep ]=D[(2^(k+1)-2^(k-j+1)+i-j-1)*m+...]
		    if(column==0)
		    {
		    	//for calculate d we just need 63 tthreads but B and C we need 63*63 threads
		    	//so in step :step, each thread will work on the row th value in each block in that step,sicne there are 63 threads.
		    	for(int i=1;i<=iloopstep;i++)
		    {

		    	float sumCD1=0.0;
		    	for(int k=0;k<m;k++)
		    	{

		    		sumCD1=sumCD1+oldC[row*m+k]*deviceD[(countHelper1-countHelper2+i*2-1-step)*m+k];
		    	}

		    	float sumCD2=0.0;
		    	for(int k=0;k<m;k++)
		    	{
		    		sumCD2=sumCD2+oldC[row*m+k]*deviceD[(countHelper1-countHelper2+i*2+1-step)*m+k];
		    	}

		    	float sumBD=0.0;
		    	for(int k=0;k<m;k++)
		    	{
		           sumBD=sumBD+oldB[row*m+k]*deviceD[(countHelper1-countHelper2+i*2-step)*m+k];
		    	}

		    	deviceD[(countHelper1-countHelper2/2+i-step-1)*m+row]=sumCD1+sumCD2-sumBD;
		    	//printf("in cuda index %d value %lf: \n",(countHelper1-countHelper2/2+i-step-1)*m+row,deviceD[(countHelper1-countHelper2/2+i-step-1)*m+row]);
		    	//printf("gpu:%lf:",newD[(i*multiplier-1)*m+row]);
		    }

		    }
		    
        }
       //sync the thread before go to the next step.
        __syncthreads();

   /*     if(row==0&&column==0)
        {
            for(int i=0;i<9;i++)
            {
              printf("%lf ",oldD[i]);	
            }
          printf("\n");	
        }*/

    }
//***************************begin of unblock version of cyclic reduction*********************************************************************************//
     __global__ void CalculatePArrayKernel(int step,int blockRow, int blockColumn,float* deviceA, float* deviceB, float* deviceC, float* deviceD)
    {
      int bx=blockIdx.x;
      int by=blockIdx.y;
      int tx=threadIdx.x;
      int ty=threadIdx.y;

      int helper11=pow(2.0,(EXPO+1)*1.0);
      int helper22=pow(2.0,(EXPO-step+1)*1.0);
      int helper44=pow(2.0,(EXPO-step+2)*1.0);
      int helper33=pow(2.0,EXPO*1.0)-1;
        //printf("step is running: %d \n",step);

     // if(helper3<pow(2.0,(EXPO-step)*1.0)-1)
        //--step 1 is special case.
     /*  if((tx!=(blockColumn-1))&&(ty!=(blockRow-1)))-----this is very important branch divergence happen here, need
     //to figure out how exactly cuda works!!
        /*****calcualte A******************/
        int helper1=helper11;
        int helper2=helper22;
        int helper4=helper44;
        int flag=0;//special for step1.
        if(step==1)
        {
            helper1=0;
            helper2=0;
            helper4=0;
            flag=1;
        }

        int helper3=ty*blockColumn+tx+1;
        if(helper3<=(pow(2.0,1.0*(EXPO-step))-1.0))
        {
        float ahelperfora1=deviceA[-step+helper1-helper4+2*(helper3)];
        float ahelperfora2=deviceA[-step+helper1-helper4+2*(helper3)-1];
        float bhelperfora1=deviceB[-step+helper1-helper4+2*(helper3)-1];
        deviceA[-1-step+helper1-helper2+helper3+flag*(1+helper33)]=-1*(ahelperfora1)*ahelperfora2/bhelperfora1;

        //*****calculate C******************/
        float chelperforc1=deviceC[-step+helper1-helper4+2*(helper3)];
        float chelperforc2=deviceC[-step+helper1-helper4+2*(helper3)+1];
        float bhelperforc1=deviceB[-step+helper1-helper4+2*(helper3)+1];
        deviceC[-1-step+helper1-helper2+helper3+flag*(1+helper33)]=-1*chelperforc1*chelperforc2/bhelperforc1;

        //calculate B***********************************************//
        float bhelperforb1=deviceB[-step+helper1-helper4+2*(helper3)];
        float bhelperforb2=deviceB[-step+helper1-helper4+2*(helper3)-1];
        float bhelperforb3=deviceB[-step+helper1-helper4+2*(helper3)+1];
        float ahelperforb1=deviceA[-step+helper1-helper4+2*(helper3)];
        float ahelperforb2=deviceA[-step+helper1-helper4+2*(helper3)+1];
        float chelperforb1=deviceC[-step+helper1-helper4+2*(helper3)-1];
        float chelperforb2=deviceC[-step+helper1-helper4+2*(helper3)];
        deviceB[-1-step+helper1-helper2+helper3+flag*(1+helper33)]=bhelperforb1-ahelperforb1/bhelperforb2*chelperforb1-chelperforb2/bhelperforb3*ahelperforb2;

        //calculate D***************************************************//
        float dhelperford1=deviceD[-step+helper1-helper4+2*(helper3)];
        float dhelperford2=deviceD[-step+helper1-helper4+2*(helper3)-1];
        float dhelperford3=deviceD[-step+helper1-helper4+2*(helper3)+1];
        float ahelperford1=deviceA[-step+helper1-helper4+2*(helper3)];
        float bhelperford1=deviceB[-step+helper1-helper4+2*(helper3)-1];
        float bhelperford2=deviceB[-step+helper1-helper4+2*(helper3)+1];
        float chelperford1=deviceC[-step+helper1-helper4+2*(helper3)];
        deviceD[-1-step+helper1-helper2+helper3+flag*(1+helper33)]=dhelperford1-ahelperford1/bhelperford1*dhelperford2-chelperford1/bhelperford2*dhelperford3;
    /*    for(int i=0;i<6;i++)
        {
        	//printf("cudab %lf \n",deviceB[i]);
        	printf("cudab %lf \n",deviceB[i]);
        }

        for(int i=0;i<6;i++)
        {
        	//printf("cudab %lf \n",deviceB[i]);
        	printf("cudad %lf \n",deviceD[i]);
        }*/
    }

        __syncthreads();
    }
    

        __global__ void BackwardKernel(int k,int blockRow, int blockColumn,float* deviceA, float* deviceB, float* deviceC, float* deviceD,float* deviceFinalX,float initialValue)
     {
      int bx1=blockIdx.x;
      int by1=blockIdx.y;
      int tx1=threadIdx.x;
      int ty1=threadIdx.y;
      //printf("inside of kernle %f \n",deviceFinalX[4]);

      int backhelper1=ty1*blockColumn+tx1+1;
      int backhelper2=2*backhelper1-1;//(int((2*backhelper1-1)*pow(2.0,1.0*(k-1))))/(int)(pow(2.0,(k-1)*1.0));
      int backhelper3=(int)pow(2.0,(EXPO+1)*1.0);
      int backhelper4=(int)pow(2.0,(EXPO-k+2)*1.0);


      int h=(int)(pow(2.0,1.0*(k-1)));

      float backhelperd=deviceD[-k+backhelper3-backhelper4+backhelper2];
      float backhelpera=deviceA[-k+backhelper3-backhelper4+backhelper2];
      float backhelperb=deviceB[-k+backhelper3-backhelper4+backhelper2];
      float backhelperc=deviceC[-k+backhelper3-backhelper4+backhelper2];

      int xindex1=backhelper2*pow(2.0,1.0*(k-1))-h;
      int xindex2=backhelper2*pow(2.0,1.0*(k-1))+h;

      //so thread i will be in charge of (2i-1)*2^(k-1) calculation
      //printf("%d ",int((2*backhelper1-1)*pow(2.0,1.0*(k-1))));
      deviceFinalX[(int)(backhelper2*pow(2.0,1.0*(k-1)))]=(backhelperd-backhelpera*deviceFinalX[xindex1]-backhelperc*deviceFinalX[xindex2])*1.0/backhelperb;

      __syncthreads();
     }
      
//***************************end of not block version of cyclic reduction*********************************************************************************//
    
    int main()
    {


      //matrix size will be 63*63 as our setup
      int m=pow(2,EXPO)-1;
      int loopH=pow(2,EXPO-1);
      int conHelp=4*loopH;
         

      //syntax will follow the  routine in the book
      float *B;
      float *C;
      float *D;
      float *X; //X to store the solution
      float *newB;
      float *newC;
 
      int b=1;
      int a=0;
      int maxBlockSize=16;


      //B and C share the same chuck length 
      int chunkLength=m*m;
      float delta=(b-a)*1.0/(m+1.0);
      float deltaSquare=delta*delta;
      int chunkSize=chunkLength*sizeof(float); 
      //need to store all the version of D, it will be 2^k-k-1 block and each block has m value
      int dLength=(pow(2,EXPO+1)-EXPO-2)*m;
      int dSize=dLength*sizeof(float);
     
     


      B=(float*)malloc(chunkSize);
      C=(float*)malloc(chunkSize);
      D=(float*)malloc(dSize);
      //this is to store the final answer
      X=(float*)malloc(chunkSize);
      newB=(float*)malloc(chunkSize);
      newC=(float*)malloc(chunkSize);
      //newD=(float*)malloc(dSize);

          
      //initilize B

      for(int i=0;i<m;i++)
      {
      	for(int j=0;j<m;j++)
      	{
      		B[i*m+j]=0.0;
      		C[i*m+j]=0.0;
      	}
      }
      

      for(int i=0;i<m;i++)
      {
      	B[i*m+i]=-4.0;
      	if(i!=0)
      	{
         B[i*m+i-1]=1.0;
      	}
      	if(i!=m-1)
      	{
      	 B[i*m+i+1]=1.0;;
      	}
      }
  

      //initilize C
      for(int i=0;i<m;i++)
      {
      	C[i*m+i]=1.0;
      } 
    
    //the first 2^k-1 will be the step 0 initial value
      for(int i=0;i<m;i++)
      {
       for(int j=0;j<m;j++)
       {
       	float x=(j+1)*delta;
       	float y=(i+1)*delta;
       	D[i*m+j]=(2*x*x+2*y*y-2*x-2*y)*deltaSquare;
       	//printf("%lf",D[i*m+j]);
       }
        //printf("\n");
      }
      //other value initilized to be 0 at the beginnig
      for(int i=m*m;i<dLength;i++)
      {
      	D[i]=0.0;
      }

      //initilize x
      for(int i=0;i<m;i++)
      {
      	for(int j=0;j<m;j++)
      	{
      		X[i*m+j]=0.0; 
      	}
      }
      //printf("let test this2:\n");

      float *deviceB,*deviceC,*deviceD,*deviceX,*devicenewB,*devicenewC;
      cudaMalloc((void**)&deviceB,chunkSize);
      cudaMalloc((void**)&deviceC,chunkSize);
      cudaMalloc((void**)&deviceD,dSize);
      cudaMalloc((void**)&deviceX,chunkSize);
      cudaMalloc((void**)&devicenewB,chunkSize);
      cudaMalloc((void**)&devicenewC,chunkSize);
      //cudaMalloc((void**)&devicenewD,chunkSize);

      cudaMemcpy(deviceB,B,chunkSize,cudaMemcpyHostToDevice);  //store previous value
      cudaMemcpy(deviceC,C,chunkSize,cudaMemcpyHostToDevice);
      cudaMemcpy(deviceD,D,dSize,cudaMemcpyHostToDevice);
      cudaMemcpy(deviceX,X,chunkSize,cudaMemcpyHostToDevice);
      cudaMemcpy(devicenewB,newB,chunkSize,cudaMemcpyHostToDevice);  //store current stored value
      cudaMemcpy(devicenewC,newC,chunkSize,cudaMemcpyHostToDevice);
     // cudaMemcpy(devicenewD,newD,chunkSize,cudaMemcpyHostToDevice);
        
        //int gridSize=((m+1)/maxBlockSize)*((m+1)/maxBlockSize); //gridSize for this problem will be 16
         	//dim3 dimGrid(1,gridSize)
      	dim3 dimGrid(1,1);  //since the maximum process we are going to use will be 63*63

        int blockRow=maxBlockSize;//pow(2,EXPO/2); //here will be 8 and 8
        int blockColumn=maxBlockSize;//pow(2,EXPO/2); //here will be 8 and 8
        dim3 dimBlock(blockColumn,blockRow);

      for(int step=1;step<EXPO;step++)
      {
      	//so the logic here will be if step is odd, then it use B,C,D as the old value and new value into newB, newC,newD.
      	//if step is even, then use newB,newC,newD as the old value and put the update value into B,C,D.
      
        //here is to calculate the d(2^(k-1))(K-1) in the book
        CalculateTheD<<<dimGrid,dimBlock>>>(step,deviceB,deviceC,deviceD,deviceX,devicenewB,devicenewC);
      }
      cudaDeviceSynchronize();
      //the last step here will be 5 so it will write its new value into newB, newC, newD. 
      cudaMemcpy(D,deviceD,dSize,cudaMemcpyDeviceToHost);
    /*  for (int i=0;i<m;i++)
      {
      	if(i%8==0)
      	{
      		printf("\n");
      	}
      	printf("%lf ",newD[3+i]);
      }*/
      //release some of the memory
      cudaFree(deviceB);
      cudaFree(deviceC);
      //cudaFree(deviceD);
      cudaFree(devicenewB);
      cudaFree(devicenewC);
      //cudaFree(devicenewD);
      
      free(B);
      free(C);
      //free(D);
      free(newB);
      free(newC);
      //free(newD);

      /*cudaMemcpy(deviceB,B,chunkSize,cudaMemcpyHostToDevice);
      cudaMemcpy(deviceC,C,chunkSize,cudaMemcpyHostToDevice);*/

      //z will D in the not block version of cyclic reduction, ZA, ZB, ZC will corresponding to A, B and C
      float *Z,*ZA,*ZB,*ZC,*FinalX;
      int finalLengthX=(int)pow(2,EXPO)+1;
      int chunkLengthZ=(pow(2,EXPO)-1)*2+1;
      int zSize=chunkLengthZ*sizeof(float);
      
      Z=(float*)malloc(zSize);
      ZA=(float*)malloc(zSize);
      ZB=(float*)malloc(zSize);
      ZC=(float*)malloc(zSize);
      FinalX=(float*)malloc(finalLengthX*sizeof(float));  //the first and last one should be know by the boundary condition

      float *deviceZ,*deviceZA,*deviceZB, *deviceZC,*deviceFinalX;
	    cudaMalloc((void**)&deviceZ,zSize);
	    cudaMalloc((void**)&deviceZA,zSize);
	    cudaMalloc((void**)&deviceZB,zSize);
	    cudaMalloc((void**)&deviceZC,zSize);
	    cudaMalloc((void**)&deviceFinalX,finalLengthX*sizeof(float));


      //set up the matrix step 
      for(int j=1;j<=loopH;j++)
      {
      	//for each j, za,zb,zc all going to be different
      	ZA[0]=0;

      	for(int i=1;i<m;i++)
      	{
      		ZA[i]=1.0;
      	}
      	//else will be 0,since it has been seperate to half and half
        for(int i=m;i<chunkLengthZ;i++)
        {
          ZA[i]=0;
        }

        for(int i=0;i<m;i++)
        {
          ZB[i]=-4.0+2*cos((2.0*j-1.0)/(m+1.0)*PI);
          //printf("zb:%f \n",ZB[i]);
        }
        for(int i=m;i<chunkLengthZ;i++)
        {
          ZB[i]=0;
        }

        ZC[m-1]=0;
        for(int i=0;i<m-1;i++)
        {
            ZC[i]=1.0;
        }
        for(int i=m;i<chunkLengthZ;i++)
        {
          ZC[i]=0;
        }

        //if it is the first step z will be from d, otherwise, z will be from the previous solution of x
        if(j==1)
        {
        	for(int i=0;i<m;i++)
        	{
        		/*Z[i]=newD[(loopH-1)*m+i]*(-1.0);
        		printf("this original one being called? %lf \n",Z[i]);*/
        		Z[i]=D[((int)pow(2.0,EXPO+1.0)-3-EXPO)*m+i]*(-1.0);
				printf("z value: %lf \n",Z[i]);
        	}
        	 for(int i=m;i<chunkLengthZ;i++)
		        {
		          Z[i]=0;
		        }
        }
        else
        {
        	for(int i=0;i<m;i++)
        	{
             //to do this will be x
        		Z[i]=FinalX[i+1];
        		//printf("does this ever called? %lf \n",Z[i]);
        	}
        	 for(int i=m;i<chunkLengthZ;i++)
		        {
		          Z[i]=0;
		        }
        }

        //now need to call the cyclic function to find the solution of x

        cudaMemcpy(deviceZ,Z,zSize,cudaMemcpyHostToDevice);
        cudaMemcpy(deviceZA,ZA,zSize,cudaMemcpyHostToDevice);
        cudaMemcpy(deviceZB,ZB,zSize,cudaMemcpyHostToDevice);
        cudaMemcpy(deviceZC,ZC,zSize,cudaMemcpyHostToDevice);

        for(int j=1;j<EXPO;j++)
        {
        //the lock size should change, the first step it will need 2^(n-j)-1, so first step will be 3 if n=3
        dim3 dimGrid(1,1);
        int blockRow=pow(2,(EXPO-j)/2);
        //printf("blockrow is :%d \n",blockRow);
        int blockColumn=pow(2,EXPO-j-(EXPO-j)/2);
        //printf("blockColumn is :%d \n",blockColumn);
        dim3 dimBlock(blockColumn,blockRow);
          //in each step the processor being used should decrease should be 2^(n-j)-1 in jth step
        CalculatePArrayKernel<<<dimGrid,dimBlock>>>(j,blockRow,blockColumn,deviceZA,deviceZB,deviceZC,deviceZ);

        }

          //backward
        //copy the device vector to host
        //cudaMemcpy(ZA,deviceZA,chunkSize,cudaMemcpyDeviceToHost);
       // sleep(20);
        cudaDeviceSynchronize(); //cpu will wait until cuda finish the job, this is such important function!
        cudaMemcpy(ZB,deviceZB,zSize,cudaMemcpyDeviceToHost);
        /*for(int i=0;i<2*m;i++)
        {
        	printf("zbresult:%lf \n",ZB[i]);
        }*/
        //cudaMemcpy(C,deviceC,chunkSize,cudaMemcpyDeviceToHost);
        cudaMemcpy(Z,deviceZ,zSize,cudaMemcpyDeviceToHost);
        int lastIndex=(int)pow(2,EXPO+1)-EXPO-3;
        float initialValue=Z[lastIndex]/ZB[lastIndex];
        //printf("initial value: %lf \n",initialValue);
        FinalX[0]=0;
        FinalX[(int)pow(2,EXPO-1)]=initialValue;
        //printf("the value in the middle is: %f and this suppose to close to 0.5 when n goes big! \n",FinalX[(int)pow(2,EXPO-1)]);

        cudaMemcpy(deviceFinalX,FinalX,finalLengthX*sizeof(float),cudaMemcpyHostToDevice);
        for(int k=EXPO-1;k>=1;k--)
        {
          //so the most one will use 2^(n-k) variable will be covered!
        dim3 dimGrid(1,1);
        int blockRow=pow(2,(EXPO-k)/2);
        int blockColumn=pow(2,EXPO-k-(EXPO-k)/2);
        dim3  dimBlock(blockColumn,blockRow);
        
        BackwardKernel<<<dimGrid,dimBlock>>>(k,blockRow,blockColumn,deviceZA,deviceZB,deviceZC,deviceZ,deviceFinalX,initialValue);
        }
         cudaDeviceSynchronize();

        cudaMemcpy(FinalX,deviceFinalX,finalLengthX*sizeof(float),cudaMemcpyDeviceToHost);
      }

      printf("\n final result for x(2^(k-1) block which should have %d values in it:\n",m);
       for (int i=1;i<finalLengthX-1;i++)
      {
       //this will we stored in X the 2^(k-1) the block.
        X[(loopH-1)*m+i-1]=FinalX[i];
      	printf("index: %d, %lf ",(loopH-1)*m+i-1,FinalX[i]);
      }
    
    //now need to do the block wise backsubstitution based on the formula of 5.4.2.17
     for(int step=EXPO-1;step>=1;step--)
     {
      //based on formula 5.4.2.30
     	//ok this is loop trhough the matrix in 5.4.2.17
     	int help1=pow(2,EXPO-step);
     	int localloopH=pow(2,step-1);
     	int thetaHelper=pow(2,step);
     	//inside of each step, you have this much of sybmatrix to solve
     	for(int backStep=1;backStep<=help1;backStep++)
     	{
     		//factorize B(step-1)
     		//first and last one need to be treat specially, C[j-1] will be just identity matrix here

     	
     	   	//************************************************************//
     	   	                 //this is to loop through the factorization
						     for(int j=1;j<=localloopH;j++)
						      {
						      	//for each j, za,zb,zc all going to be different
						      	ZA[0]=0;

						      	for(int i=1;i<m;i++)
						      	{
						      		ZA[i]=1.0;
						      	}
						      	//else will be 0,since it has been seperate to half and half
						        for(int i=m;i<chunkLengthZ;i++)
						        {
						          ZA[i]=0;
						        }

						        for(int i=0;i<m;i++)
						        {
						          ZB[i]=-4.0+2*cos((2.0*backStep-1.0)/(thetaHelper)*PI);
						          //printf("zb:%f \n",ZB[i]);
						        }
						        for(int i=m;i<chunkLengthZ;i++)
						        {
						          ZB[i]=0;
						        }

						        ZC[m-1]=0;
						        for(int i=0;i<m-1;i++)
						        {
						            ZC[i]=1.0;
						        }
						        for(int i=m;i<chunkLengthZ;i++)
						        {
						          ZC[i]=0;
						        }
						        //if it is the first step z will be from d, otherwise, z will be from the previous solution of x
						        if(j==1)
						        {
						        	//the first backsetp and last backstep will be special
						        	if(backStep==1)
						        	{
                                      //teh first d will be d(t-s)(j-1)-c(j-1)x(t)
								        		for(int i=0;i<m;i++)
								        	{
								        		//Z[i]=D[(loopH-1)*m+i]*(-1.0);
								        		//printf("this original one being called? %lf \n",Z[i]);
								        		Z[i]=D[(conHelp-4*help1-step+1)*m+i]-X[(thetaHelper-1)*m+i];
								        		printf("z value: %lf \n",Z[i]);

								        	}
								        	 for(int i=m;i<chunkLengthZ;i++)
										        {
										          Z[i]=0;
										        }
						        	}
						        	else if(backStep==help1)
						        	{
					        				for(int i=0;i<m;i++)
							        	{
							        		//Z[i]=D[(loopH-1)*m+i]*(-1.0);
							        		//printf("this original one being called? %lf \n",Z[i]);
							        		Z[i]=D[(conHelp-2*help1-1-step)*m+i]-X[(conHelp/2-thetaHelper-1)*m+i];

							        	}
							        	 for(int i=m;i<chunkLengthZ;i++)
									        {
									          Z[i]=0;
									        }

						        	}
						        	else //this is at the middle bakcstep
						        	{
						        			for(int i=0;i<m;i++)
							        	{
							        		//Z[i]=D[(loopH-1)*m+i]*(-1.0);
							        		//printf("this original one being called? %lf \n",Z[i]);
							        		Z[i]=D[(2*backStep-1-step+conHelp-2*help1)*m+i]-X[(backStep*thetaHelper-1)*m+i]-X[((backStep-1)*thetaHelper-1)*m+i];
							        	}
							        	 for(int i=m;i<chunkLengthZ;i++)
									        {
									          Z[i]=0;
									        }

						        	}
						        }
						        else
						        {
						        	for(int i=0;i<m;i++)
						        	{
						             //to do this will be x
						        		Z[i]=FinalX[i+1];
						        		//printf("does this ever called? %lf \n",Z[i]);
						        	}
						        	 for(int i=m;i<chunkLengthZ;i++)
								        {
								          Z[i]=0;
								        }
						        }

						        //now need to call the cyclic function to find the solution of x

						        cudaMemcpy(deviceZ,Z,zSize,cudaMemcpyHostToDevice);
						        cudaMemcpy(deviceZA,ZA,zSize,cudaMemcpyHostToDevice);
						        cudaMemcpy(deviceZB,ZB,zSize,cudaMemcpyHostToDevice);
						        cudaMemcpy(deviceZC,ZC,zSize,cudaMemcpyHostToDevice);

						        for(int j=1;j<EXPO;j++)
						        {
						        //the lock size should change, the first step it will need 2^(n-j)-1, so first step will be 3 if n=3
						        dim3 dimGrid(1,1);
						        int blockRow=pow(2,(EXPO-j)/2);
						        //printf("blockrow is :%d \n",blockRow);
						        int blockColumn=pow(2,EXPO-j-(EXPO-j)/2);
						        //printf("blockColumn is :%d \n",blockColumn);
						        dim3 dimBlock(blockColumn,blockRow);
						          //in each step the processor being used should decrease should be 2^(n-j)-1 in jth step
						        CalculatePArrayKernel<<<dimGrid,dimBlock>>>(j,blockRow,blockColumn,deviceZA,deviceZB,deviceZC,deviceZ);

						        }

						          //backward
						        //copy the device vector to host
						        //cudaMemcpy(ZA,deviceZA,chunkSize,cudaMemcpyDeviceToHost);
						       // sleep(20);
						        cudaDeviceSynchronize(); //cpu will wait until cuda finish the job, this is such important function!
						        cudaMemcpy(ZB,deviceZB,zSize,cudaMemcpyDeviceToHost);
						     /*   for(int i=0;i<2*m;i++)
						        {
						        	printf("zbresult:%lf \n",ZB[i]);
						        }*/
						        //cudaMemcpy(C,deviceC,chunkSize,cudaMemcpyDeviceToHost);
						        cudaMemcpy(Z,deviceZ,zSize,cudaMemcpyDeviceToHost);
						        int lastIndex=(int)pow(2,EXPO+1)-EXPO-3;
						        float initialValue=Z[lastIndex]/ZB[lastIndex];
						        //printf("initial value: %lf \n",initialValue);
						        FinalX[0]=0;
						        FinalX[(int)pow(2,EXPO-1)]=initialValue;
						        //printf("the value in the middle is: %f and this suppose to close to 0.5 when n goes big! \n",FinalX[(int)pow(2,EXPO-1)]);

						        cudaMemcpy(deviceFinalX,FinalX,finalLengthX*sizeof(float),cudaMemcpyHostToDevice);
						        for(int k=EXPO-1;k>=1;k--)
						        {
						          //so the most one will use 2^(n-k) variable will be covered!
						        dim3 dimGrid(1,1);
						        int blockRow=pow(2,(EXPO-k)/2);
						        int blockColumn=pow(2,EXPO-k-(EXPO-k)/2);
						        dim3  dimBlock(blockColumn,blockRow);
						        
						        BackwardKernel<<<dimGrid,dimBlock>>>(k,blockRow,blockColumn,deviceZA,deviceZB,deviceZC,deviceZ,deviceFinalX,initialValue);
						        }
						         cudaDeviceSynchronize();

						        cudaMemcpy(FinalX,deviceFinalX,finalLengthX*sizeof(float),cudaMemcpyDeviceToHost);

						      }
                              printf("\n");
						      for(int i=1;i<finalLengthX-1;i++)
						       {
						       	X[((2*backStep-1)*localloopH-1)*m+i-1]=FinalX[i];
                                printf("%lf \n",FinalX[i]);
						       }

     	   	//************************************************************//
     	}

     }

    /* printf("\n");
       for (int i=0;i<m*m;i++)
      {
       //this will we stored in X the 2^(k-1) the block.
      	if(m%10==0)
      	{
      		printf("\n");
      	}
        printf("[%d]:%lf ",i,X[i]);
      }*/
  }





