    #include <stdio.h>
    #include <cuda.h>
    #include <time.h>
    #define EXPO 9
   

    //this is the kernel to calculate the P=(a,b,c,d)
    //need to pass in the step which is j, and then figure out which thread to work on
    //the calculation in (2^j,2*2^j,3*2^j....)
    __global__ void CalculatePArrayKernel(int step,int powerNumber,int totalNumber,float** A, float** B, float** C, float** D)
    {
      //maybe have some way to enhance this, since some block don't need to load C and D
      //511 is getting from pow(2,EXPO-1)-1 and can be changed later.
      /*__shared__ float A_Local[511];
      __shared__ float B_Local[511];
      __shared__ float C_Local[511];
      __shared__ float D_Local[511];*/
      extern __shared__ float wholeArray[]; //dynamically allocate shared memory
      float* A_Local=(float*)&wholeArray[511];
      float* B_Local=(float*)&wholeArray[1022];
      float* C_Local=(float*)&wholeArray[1533];
      float* D_Local=(float*)&wholeArray[2044];

      int bx=blockIdx.x;
      int by=blockIdx.y;
      int tx=threadIdx.x;
      int ty=threadIdx.y;
      int BLOCKSIZE=16;
      

      int temp=ty*BLOCKSIZE+tx;
      //need to notice threadId in different block should be the same
     /* for(int i=0;i<511;i++)
      {*/
        if(by!=1) //A has to be loaded in these blocks
        {
        A_Local[temp]=A[step-1][temp];
        }
        if(by!=0)
        {
         C_Local[temp]=C[step-1][temp];
        }
        if(by==3)
        {
         D_Local[temp]=D[step-1][temp];
        }
        //B need to be loaded for all the block, no if should apply to that
        B_Local[temp]=B[step-1][temp];
        __syncthreads();

            if(by==0)
            {
            for(int i=0;i<10;i++)
            {
                printf("cuda A: %f in step :%d \n", A_Local[i],step);
        
            }
        }


       if(by==0)//means this is the first block ,As will be calculated here
       {
        //if for boundary check
        if(temp-powerNumber>0)
        {
        A[step][temp]=(-1)*A_Local[temp]/(B_Local[temp-powerNumber])*A_Local[temp-powerNumber];
        }
        else
        {
         A[step][temp]=0;
        }
       }

       if(by==2) //means this is the third block, Cs will be calculated here
       {
        if(temp+powerNumber<totalNumber)
        {
         C[step][temp]=(-1)*C_Local[temp]/B_Local[temp+powerNumber]*C_Local[temp+powerNumber];   
        }
        else
        {
         C[step][temp]=0;
        }
       }

       if(by==1) //means this is the second block, Bs will be calculated here
       {
        if(temp-powerNumber>0 && temp+powerNumber<totalNumber)
        {
        B[step][temp]=B_Local[temp]-A_Local[temp]/B_Local[temp-powerNumber]*C_Local[temp-powerNumber]-C_Local[temp]/B_Local[temp+powerNumber]*A_Local[temp+powerNumber];
        }
        else if(temp-powerNumber>0 && temp+powerNumber>=totalNumber)
        {
        B[step][temp]=B_Local[temp]-A_Local[temp]/B_Local[temp-powerNumber]*C_Local[temp-powerNumber];
        }
        else if(temp-powerNumber<=0 && temp+powerNumber<totalNumber)
        {
        B[step][temp]=B_Local[temp]-C_Local[temp]/B_Local[temp+powerNumber]*A_Local[temp+powerNumber];
        }
        else
        {
        B[step][temp]=B_Local[temp];
        }
       }

       if(by==3) //this is the fourth block, Ds will be calculated here
       { 
        if(temp-powerNumber>0 && temp+powerNumber<totalNumber)
        {
        D[step][temp]=D_Local[temp]-A_Local[temp]/B_Local[temp-powerNumber]*D_Local[temp-powerNumber]-C_Local[temp]/B_Local[temp+powerNumber]*D_Local[temp+powerNumber]; 
        }
        else if(temp-powerNumber>0 && temp+powerNumber>=totalNumber)
        {
        D[step][temp]=D_Local[temp]-A_Local[temp]/B_Local[temp-powerNumber]*D_Local[temp-powerNumber];
        }
        else if(temp-powerNumber<=0 && temp+powerNumber<totalNumber)
        {
        D[step][temp]=D_Local[temp]-C_Local[temp]/B_Local[temp+powerNumber]*D_Local[temp+powerNumber]; 
        }
        else
        {
        D[step][temp]=D_Local[temp];
        }   
       }
      //}
    }

    int main()
    {
        
        int m=pow(2,EXPO)-1;
        int b=1;
        int a=0;
        float delta=(b-a)*1.0/(m+1.0);
        /*int **by_global, **bx_global;*/
        /*float* A;
        float* B;
        float* C;
        float* D;

        A=(float*)malloc(m*sizeof(float));
        B=(float*)malloc(m*sizeof(float));
        C=(float*)malloc(m*sizeof(float));
        D=(float*)malloc(m*sizeof(float));*/

        float **A; //need a two dimension array to store different versin of A, so A will be A[step][i]; step is how many step will be 9 here and i will be 512 here.
        float **B;
        float **C;
        float **D;
       //each version j loop through 1 to n-1 and also the initial value so we need to 
        //remember EXPO of them
        //we need to remember them in order to use them later in back substitution


        A=(float**)malloc(EXPO*sizeof(float*));
        B=(float**)malloc(EXPO*sizeof(float*));
        C=(float**)malloc(EXPO*sizeof(float*));
        D=(float**)malloc(EXPO*sizeof(float*));

        for(int i=0;i<EXPO;i++)
        {
            A[i]=(float*)malloc(m*sizeof(float));
        }
         for(int i=0;i<EXPO;i++)
        {
            B[i]=(float*)malloc(m*sizeof(float));
        }
        for(int i=0;i<EXPO;i++)
        {
            C[i]=(float*)malloc(m*sizeof(float));
        }
        for(int i=0;i<EXPO;i++)
        {
            D[i]=(float*)malloc(m*sizeof(float));
        }

       //initialize A,B,C,D
        A[0][0]=0;
        for(int i=1;i<m;i++)
        {
            A[0][i]=1-delta*delta*0.5*i;
            if(i<10)
            {
                printf("%f \n",A[0][i]);
            }
        }
        for(int i=0;i<m;i++)
        {
            B[0][i]=-2+delta*delta*1.0;
        }
        C[0][m-1]=0;
        for(int i=0;i<m-1;i++)
        {
            C[0][i]=1+0.5*delta*delta*i;
        }
        D[0][0]=2*pow(delta,3)-(1-0.5*delta*delta);
        for(int i=1;i<m;i++)
        {
            D[0][i]=2*(i+1)*pow(delta,3);
        }
        clock_t begin,end;
        begin=clock();
        //so need to set up different grid dimension for different value of j,
        //when j decrease the size of the thread using will decrease.
        dim3 dimGrid(4,1); //so we have 4 blocks each block will in charge a,b,c,d respectly.
        dim3 dimBlock(16,16);

        //m is the size
        float ** AT,**BT,**CT,**DT;
        int size=m*sizeof(float*);

        cudaMalloc((void**)&AT,size);
        cudaMalloc((void**)&BT,size);
        cudaMalloc((void**)&CT,size);
        cudaMalloc((void**)&DT,size);

        cudaMemcpy(AT,A,size,cudaMemcpyHostToDevice);
        cudaMemcpy(BT,B,size,cudaMemcpyHostToDevice);
        cudaMemcpy(CT,C,size,cudaMemcpyHostToDevice);
        cudaMemcpy(DT,D,size,cudaMemcpyHostToDevice);

        printf("this is to test EXPO should see 9 here: %d \n",EXPO);

        for(int j=1;j<EXPO;j++)
        {
            //for each j do the work sequentially, inside this loop do work parallel.
          int powerNumber=pow(2,j-1);
          int totalNumber=m+1;
          //pass i the dynamically allocated shared memory among block.
           CalculatePArrayKernel<<<dimGrid,dimBlock,2044*sizeof(float)>>>(j,powerNumber,totalNumber,AT,BT,CT,DT);
           cudaThreadSynchronize();
           printf("called from host %d \n",j);
        }
        //copy data back to device
        cudaMemcpy(A,AT,size,cudaMemcpyDeviceToHost);
        cudaMemcpy(B,BT,size,cudaMemcpyDeviceToHost);
        cudaMemcpy(C,CT,size,cudaMemcpyDeviceToHost);
        cudaMemcpy(D,DT,size,cudaMemcpyDeviceToHost);
    
        double time_spent;


        end=clock();
        time_spent=(double)(end-begin)/CLOCKS_PER_SEC;
        printf("time spend for 524 n points is :%f seconds \n",time_spent);

        for(int k=0;k<100;k++)
        {
         printf("A new 1: %f \n",A[1][k]);
          printf("A new 8: %f \n",A[8][k]);
        }
        
        cudaFree(AT);
        cudaFree(BT);
        cudaFree(CT);
        cudaFree(DT);
      //release memory
        for(int i=0;i<9;i++)
        {
            free(A[i]);
        }
        free(A);

        for(int i=0;i<9;i++)
        {
            free(B[i]);
        }
        free(B);

        for(int i=0;i<9;i++)
        {
            free(C[i]);
        }
        free(C);

        for(int i=0;i<9;i++)
        {
            free(D[i]);
        }
        free(D);

        return 0;
    }