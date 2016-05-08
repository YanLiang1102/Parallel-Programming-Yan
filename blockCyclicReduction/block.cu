     #include <stdio.h>
    #include <cuda.h>
    #include <time.h>
    #define EXPO 2 //so [0,1] will be break into 2^6 intervals 64*64

    __global__ void CalculateTheD(int step,float* deviceB, float* deviceC, float* deviceD, float* deviceX, float* devicenewB, float* devicenewC, float* devicenewD)
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

      float* oldB;
      float* oldC;
      float* oldD;

      float* newB;
      float* newC;
      float* newD;

     //this is to exchange which hold the previous value which hold the current value
      if(step%2==0)
      {
      	oldB=devicenewB;
      	oldC=devicenewC;
      	oldD=devicenewD;

      	newB=deviceB;
      	newC=deviceC;
      	newD=deviceD;
      }
      else
      {
      	oldB=deviceB;
      	oldC=deviceC;
      	oldD=deviceD;
        
        newB=devicenewB;
        newC=devicenewC;
        newD=devicenewD;
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
		    if(column==0)
		    {
		    	//for calculate d we just need 63 tthreads but B and C we need 63*63 threads
		    	for(int i=1;i<=iloopstep;i++)
		    {

		    	float sumCD1=0.0;
		    	for(int k=0;k<m;k++)
		    	{
		    		sumCD1=sumCD1+oldC[row*m+k]*oldD[(i*multiplier-h-1)*m+k];
		    	}

		    	float sumCD2=0.0;
		    	for(int k=0;k<m;k++)
		    	{
		    		sumCD2=sumCD2+oldC[row*m+k]*oldD[(i*multiplier+h-1)*m+k];
		    	}

		    	float sumBD=0.0;
		    	for(int k=0;k<m;k++)
		    	{
		           sumBD=sumBD+oldB[row*m+k]*oldD[(i*multiplier-1)*m+k];
		    	}

		    	newD[(i*multiplier-1)*m+row]=sumCD1+sumCD2-sumBD;
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
       
      

    
    int main()
    {


      //matrix size will be 63*63 as our setup
      int m=pow(2,EXPO)-1;
         

      //syntax will follow the  routine in the book
      float *B;
      float *C;
      float *D;
      float *X; //X to store the solution
      float *newB;
      float *newC;
      float *newD;
      int b=1;
      int a=0;
      int maxBlockSize=16;

      //B and C share the same chuck length 
      int chunkLength=m*m;
      float delta=(b-a)*1.0/(m+1.0);
      float deltaSquare=delta*delta;
      int chunkSize=chunkLength*sizeof(float); 
     // printf("value of m %d and delta %lf!! \n",m,delta);
     


      B=(float*)malloc(chunkSize);
      C=(float*)malloc(chunkSize);
      D=(float*)malloc(chunkSize);
      X=(float*)malloc(chunkSize);
      newB=(float*)malloc(chunkSize);
      newC=(float*)malloc(chunkSize);
      newD=(float*)malloc(chunkSize);

          
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
   
      for(int i=0;i<m;i++)
      {
      	for(int j=0;j<m;j++)
      	{
      		X[i*m+j]=0.0; 
      	}
      }
      //printf("let test this2:\n");

      float *deviceB,*deviceC,*deviceD,*deviceX,*devicenewB,*devicenewC,*devicenewD;
      cudaMalloc((void**)&deviceB,chunkSize);
      cudaMalloc((void**)&deviceC,chunkSize);
      cudaMalloc((void**)&deviceD,chunkSize);
      cudaMalloc((void**)&deviceX,chunkSize);
      cudaMalloc((void**)&devicenewB,chunkSize);
      cudaMalloc((void**)&devicenewC,chunkSize);
      cudaMalloc((void**)&devicenewD,chunkSize);

      cudaMemcpy(deviceB,B,chunkSize,cudaMemcpyHostToDevice);  //store previous value
      cudaMemcpy(deviceC,C,chunkSize,cudaMemcpyHostToDevice);
      cudaMemcpy(deviceD,D,chunkSize,cudaMemcpyHostToDevice);
      cudaMemcpy(deviceX,X,chunkSize,cudaMemcpyHostToDevice);
      cudaMemcpy(devicenewB,newB,chunkSize,cudaMemcpyHostToDevice);  //store current stored value
      cudaMemcpy(devicenewC,newC,chunkSize,cudaMemcpyHostToDevice);
      cudaMemcpy(devicenewD,newD,chunkSize,cudaMemcpyHostToDevice);
        
        //int gridSize=((m+1)/maxBlockSize)*((m+1)/maxBlockSize); //gridSize for this problem will be 16
      	dim3 dimGrid(1,1);  //since the maximum process we are going to use will be 63*63
      	//int blockRow=maxBlockSize;
      	int blockRow=maxBlockSize;//pow(2,EXPO/2); //here will be 8 and 8
        int blockColumn=maxBlockSize;//pow(2,EXPO/2); //here will be 8 and 8
        dim3 dimBlock(blockColumn,blockRow);

      for(int step=1;step<EXPO;step++)
      {
      	//so the logic here will be if step is odd, then it use B,C,D as the old value and new value into newB, newC,newD.
      	//if step is even, then use newB,newC,newD as the old value and put the update value into B,C,D.
      
        //here is to calculate the d(2^(k-1))(K-1) in the book
        CalculateTheD<<<dimGrid,dimBlock>>>(step,deviceB,deviceC,deviceD,deviceX,devicenewB,devicenewC,devicenewD);
      }

      //the last step here will be 5 so it will write its new value into newB, newC, newD. 

      cudaMemcpy(newD,devicenewD,chunkSize,cudaMemcpyDeviceToHost);
      for (int i=0;i<m;i++)
      {
      	if(i%8==0)
      	{
      		printf("\n");
      	}
        printf("%lf ",newD[m+i]);
      }

      //the value of D we are look at is 

      
    /*  for(int i=0;i<chunkLength;i++)
      {
      	printf("%lf ",newB[i]);
      	if(i==32*63)
      		printf("hello! \n");
      	if(i%63==0)
      	{
      		printf("\n");
      	}
      }*/
      //printf("what about this time %lf:\n",D[63]);

    }


