    #include <stdio.h>
    #include <cuda.h>
    #include <time.h>
    #define EXPO 9
    #define BLOCKSIZE 16

    //this is the kernel to calculate the P=(a,b,c,d)
    //need to pass in the step which is j, and then figure out which thread to work on
    //the calculation in (2^j,2*2^j,3*2^j....)
    __global__ void CalculatePArrayKernel(int step, float** A, float** B, float** C, float** D)
    {
      //maybe have some way to enhance this, since some block don't need to load C and D
      int local_dimension=pow(2,EXPO-1)-1
      __shared__ float A_Local[local_dimension];
      __shared__ float B_Local[local_dimension];
      __shared__ float C_Local[local_dimension];
      __shared__ float D_Local[local_dimension];

      int bx=blockIdx.x;
      int by=blockIdx.y;
      int tx=threadIdx.x;
          int ty=threadIdx.y;

      int temp=ty*BLOCKSIZE+tx;
      //need to notice threadId in different block should be the same
      for(int i=0;i<local_dimension;i++)
      {
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

       if(by==0)//means this is the first block ,As will be calculated here
       {
        //if for boundary check
        if(temp-pow(2,step-1)>0)
        {
        A[step][temp]=(-1)*A_Local[temp]/(B_Local[temp-pow(2,step-1)])*A_Local[temp-pow(2,step-1)];
        }
        else
        {
         A[step][temp]=0;
        }
       }

       if(by==2) //means this is the third block, Cs will be calculated here
       {
        if(temp+pow(2,step-1)<pow(2,EXPO))
        {
         C[step][temp]=(-1)*C_Local[temp]/B_Local[temp+pow(2,step-1)]*C_Local[temp+pow(2,step-1)];   
        }
        else
        {
         C[step][temp]=0;
        }
        }

       if(by==1) //means this is the second block, Bs will be calculated here
       {
        if(temp-pow(2,step-1)>0 && temp+pow(2,step-1)<pow(2,EXPO))
        {
        B[step][temp]=B_Local[temp]-A_Local[temp]/B_Local[temp-pow(2,step-1)]*C_Local[temp-pow(2,step-1)]-C_Local[temp]/B_Local[temp+pow(2,step-1)]*A_Local[temp+pow(2,step-1)];
        }
        else if(temp-pow(2,step-1)>0 && temp+pow(2,step-1)>=pow(2,EXPO))
        {
        B[step][temp]=B_Local[temp]-A_Local[temp]/B_Local[temp-pow(2,step-1)]*C_Local[temp-pow(2,step-1)];
        }
        else if(temp-pow(2,step-1)<=0 && temp+pow(2,step-1)<pow(2,EXPO))
        {
        B[step][temp]=B_Local[temp]-C_Local[temp]/B_Local[temp+pow(2,step-1)]*A_Local[temp+pow(2,step-1)];
        }
        else
        {
        B[step][temp]=B_Local[temp];
        }
       }

       if(by==3) //this is the fourth block, Ds will be calculated here
       { 
        if(temp-pow(2,step-1)>0 && temp+pow(2,step-1)<pow(2,EXPO))
        {
        D[step][temp]=D_Local[temp]-A_Local[temp]/B_Local[temp-pow(2,step-1)]*D_Local[temp-pow(2,step-1)]-C_Local[temp]/B_Local[temp+pow(2,step-1)]*D_Local[temp+pow(2,step-1)]; 
        }
        else if(temp-pow(2,step-1)>0 && temp+pow(2,step-1)>=pow(2,EXPO))
        {
        D[step][temp]=D_Local[temp]-A_Local[temp]/B_Local[temp-pow(2,step-1)]*D_Local[temp-pow(2,step-1)];
        }
        else if(temp-pow(2,step-1)<=0 && temp+pow(2,step-1)<pow(2,EXPO))
        {
        D[step][temp]=D_Local[temp]-C_Local[temp]/B_Local[temp+pow(2,step-1)]*D_Local[temp+pow(2,step-1)]; 
        }
        else
        {
        D[step][temp]=D_Local[temp];
        }   
       }
      }
    }

    int main()
    {
    	
        int m=pow(2,EXPO)-1;
        int b=1;
        int a=0;
        float delta=(b-a)*1.0/(m+1.0);
        /*float* A;
        float* B;
        float* C;
        float* D;

        A=(float*)malloc(m*sizeof(float));
        B=(float*)malloc(m*sizeof(float));
        C=(float*)malloc(m*sizeof(float));
        D=(float*)malloc(m*sizeof(float));*/

        float **A; //need a two dimension array to store different versin of A
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
        return 0;
        //so need to set up different grid dimension for different value of j,
        //when j decrease the size of the thread using will decrease.
        dim3 dimGrid(4,1); //so we have 4 blocks each block will in charge a,b,c,d respectly.
        dim3 dimBlock(16,16);

        for(int j=1;j<EXPO;j++)
        {
        	//for each j do the work sequentially, inside this loop do work parallel.
          
           CalculatePArrayKernel<<<dimGrid,dimBlock>>>(j);
        }


    }