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
    

      int bx=blockIdx.x;
      int by=blockIdx.y;
      int tx=threadIdx.x;
      int ty=threadIdx.y;
     
      

      int temp=ty*BLOCKSIZE+tx;
       
      printf("hello from step \n",step);
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
           CalculatePArrayKernel<<<dimGrid,dimBlock>>>(j,powerNumber,totalNumber,AT,BT,CT,DT);
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