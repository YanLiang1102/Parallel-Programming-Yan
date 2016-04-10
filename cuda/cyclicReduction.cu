    #include <stdio.h>
    #include <cuda.h>
    #include <time.h>
    #define EXPO 3
   
    //the right way to add in cuda driver if you have an gpu
    //http://askubuntu.com/questions/451221/ubuntu-14-04-install-nvidia-driver


    //this is the kernel to calculate the P=(a,b,c,d)
    //need to pass in the step which is j, and then figure out which thread to work on
    //the calculation in (2^j,2*2^j,3*2^j....)
    __global__ void CalculatePArrayKernel(int totalStep,size_t pitch,float* A, float* B, float* C, float* D)
    {
      
      __shared__ float A_Local[7];
      __shared__ float B_Local[7];
      __shared__ float C_Local[7];
      __shared__ float D_Local[7];

      for(int step=1;step<totalStep;step++)
      {
      //this is a good graph to show how does cuda grid index working
      //http://stackoverflow.com/questions/26913683/different-way-to-index-threads-in-cuda-c
      int bx=blockIdx.x;
      int by=blockIdx.y;
      int tx=threadIdx.x;
      int ty=threadIdx.y;
      //int BLOCKSIZE=16;
      int BLOCKSIZE=3;

    /*   if(tx==0&&ty==0)
        {  printf("step: %d has been called from : \%d! \n",step,by);
            
        }*/
      
      int totalNumber=(int) pow(2.0,totalStep*1.0);
      int columnCount=totalNumber-1;
      int powerNumber=(int) pow(2.0,step-1.0);
      int stopLoading=(int) (pow(2.0,totalStep*1.0)-pow(2.0,(step-1)*1.0));
      //according to the formula the stopLoading will stop load at 2^n-2^step, that is how we get this.
      

      int temp=ty*BLOCKSIZE+tx;
      int expoStep=(int)pow(2.0,(step-1)*1.0);

    if((temp<=stopLoading)&&(temp%(expoStep))==0)
    {
        if(by!=1) //A has to be loaded in these blocks
        {
        A_Local[temp]=A[(step-1)*columnCount+temp];
        }
        if(by!=0)
        {
         C_Local[temp]=C[(step-1)*columnCount+temp];
        }
        if(by==3)
        {
         D_Local[temp]=D[(step-1)*columnCount+temp];
        }
        //B need to be loaded for all the block, no if should apply to that
        B_Local[temp]=B[(step-1)*columnCount+temp];
        __syncthreads();

        //test A_Local
        if(by==2&&tx==0&&ty==0&&step==2)
        {
            printf("I should run only once for A_Local %d! \n",columnCount);
            for(int i=0;i<=stopLoading;i++)
            {
                printf("A local %f \n",A_Local[i]);
            }

        }

       if(by==0)//means this is the first block ,As will be calculated here
       {

       if(temp-powerNumber>0)
        {
        A[step*columnCount+temp]=(-1)*A_Local[temp]/(B_Local[temp-powerNumber])*A_Local[temp-powerNumber];
        }
        else
        {
         A[step*columnCount+temp]=0;
        }
        
       }

       if(by==2) //means this is the third block, Cs will be calculated here
       {
        if(temp+powerNumber<totalNumber)
        {
         C[step*columnCount+temp]=(-1)*C_Local[temp]/B_Local[temp+powerNumber]*C_Local[temp+powerNumber];   
        }
        else
        {
         C[step*columnCount+temp]=0;
        }
       }

       if(by==1) //means this is the second block, Bs will be calculated here
       {
        if(temp-powerNumber>0 && temp+powerNumber<totalNumber)
        {
        B[step*columnCount+temp]=B_Local[temp]-A_Local[temp]/B_Local[temp-powerNumber]*C_Local[temp-powerNumber]-C_Local[temp]/B_Local[temp+powerNumber]*A_Local[temp+powerNumber];
        }
        else if(temp-powerNumber>0 && temp+powerNumber>=totalNumber)
        {
        B[step*columnCount+temp]=B_Local[temp]-A_Local[temp]/B_Local[temp-powerNumber]*C_Local[temp-powerNumber];
        }
        else if(temp-powerNumber<=0 && temp+powerNumber<totalNumber)
        {
        B[step*columnCount+temp]=B_Local[temp]-C_Local[temp]/B_Local[temp+powerNumber]*A_Local[temp+powerNumber];
        }
        else
        {
        B[step*columnCount+temp]=B_Local[temp];
        }
       }

       if(by==3) //this is the fourth block, Ds will be calculated here
       { 
        if(temp-powerNumber>0 && temp+powerNumber<totalNumber)
        {
        D[step*columnCount+temp]=D_Local[temp]-A_Local[temp]/B_Local[temp-powerNumber]*D_Local[temp-powerNumber]-C_Local[temp]/B_Local[temp+powerNumber]*D_Local[temp+powerNumber]; 
        }
        else if(temp-powerNumber>0 && temp+powerNumber>=totalNumber)
        {
        D[step*columnCount+temp]=D_Local[temp]-A_Local[temp]/B_Local[temp-powerNumber]*D_Local[temp-powerNumber];
        }
        else if(temp-powerNumber<=0 && temp+powerNumber<totalNumber)
        {
        D[step*columnCount+temp]=D_Local[temp]-C_Local[temp]/B_Local[temp+powerNumber]*D_Local[temp+powerNumber]; 
        }
        else
        {
        D[step*columnCount+temp]=D_Local[temp];
        }   
       }
   }
       __syncthreads();
     }
      //}
    }

    int main()
    {
        
        int m=pow(2,EXPO)-1;
        int b=1;
        int a=0;
        float delta=(b-a)*1.0/(m+1.0);

        float *A;
        float *B;
        float *C;
        float *D;

        int chunkSize=EXPO*m*sizeof(float);
        A=(float*)malloc(chunkSize);
        B=(float*)malloc(chunkSize);
        C=(float*)malloc(chunkSize);
        D=(float*)malloc(chunkSize);

        A[0]=0;
        //int vectorLength=EXPO*m;
        for(int i=1;i<=m;i++)
        {
            A[i]=1-delta*delta*0.5*i;
              if(i<=7)
            {
                printf("%f \n",A[i]);
            }
        }

        for(int i=0;i<m;i++)
        {
            B[i]=-2+delta*delta*1.0;
        }

        C[m-1]=0;
        for(int i=0;i<m;i++)
        {
            C[i]=1+0.5*delta*delta*i;
        }

        D[0]=0;
        for(int i=1;i<m;i++)
        {
            D[i]=2*(i+1)*pow(delta,3);
        }
        clock_t begin,end;
        begin=clock();
        //so need to set up different grid dimension for different value of j,
        //when j decrease the size of the thread using will decrease.
        dim3 dimGrid(1,4); //so we have 4 blocks each block will in charge a,b,c,d respectly.
        dim3 dimBlock(3,3);

        //http://stackoverflow.com/questions/5029920/how-to-use-2d-arrays-in-cuda
        //according to the above post, the following is the correct way to allocate 2D array on cuda devixe

        float *deviceA, *deviceB, *deviceC, *deviceD;
        size_t pitch;
        cudaMallocPitch((void**)&deviceA,&pitch,m*sizeof(float),EXPO);
        cudaMallocPitch((void**)&deviceB,&pitch,m*sizeof(float),EXPO);
        cudaMallocPitch((void**)&deviceC,&pitch,m*sizeof(float),EXPO);
        cudaMallocPitch((void**)&deviceD,&pitch,m*sizeof(float),EXPO);


        int size=EXPO*m*sizeof(float);
        cudaMemcpy(deviceA,A,size,cudaMemcpyHostToDevice);
        cudaMemcpy(deviceB,B,size,cudaMemcpyHostToDevice);
        cudaMemcpy(deviceC,C,size,cudaMemcpyHostToDevice);
        cudaMemcpy(deviceD,D,size,cudaMemcpyHostToDevice);
        //deviceA, deviceB, deviceC, deviceD is designed to be the global memory of cuda.
        CalculatePArrayKernel<<<dimGrid,dimBlock>>>(EXPO,pitch,deviceA,deviceB,deviceC,deviceD);

        cudaMemcpy(A,deviceA,size,cudaMemcpyDeviceToHost);
        cudaMemcpy(B,deviceB,size,cudaMemcpyDeviceToHost);
        cudaMemcpy(C,deviceC,size,cudaMemcpyDeviceToHost);
        cudaMemcpy(D,deviceD,size,cudaMemcpyDeviceToHost);
    
        double time_spent;


        end=clock();
        time_spent=(double)(end-begin)/CLOCKS_PER_SEC;
        printf("time spend for 524 n points is :%f seconds \n",time_spent);
/*
        printf("hey here is the result matrix: \n");
        for(int k=0;k<EXPO*m;k++)
        {
            if(k%7==0)
         {
            printf("\n");
         }
         printf("%f ",B[k]);
         
        }*/
        
        cudaFree(deviceA);
        cudaFree(deviceB);
        cudaFree(deviceC);
        cudaFree(deviceD);

        free(A);
        free(B);
        free(C);
        free(D);

        return 0;
    }