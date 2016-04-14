    #include <stdio.h>
    #include <cuda.h>
    #include <time.h>
    #define EXPO 3
   
    //the right way to add in cuda driver if you have an gpu
    //http://askubuntu.com/questions/451221/ubuntu-14-04-install-nvidia-driver


    //this is the kernel to calculate the P=(a,b,c,d)
    //need to pass in the step which is j, and then figure out which thread to work on
    //the calculation in (2^j,2*2^j,3*2^j....)
    __global__ void CalculatePArrayKernel(int totalStep,int step,int blockRow, int blockColumn,float* deviceA, float* deviceB, float* deviceC, float* deviceD)
    {
      int bx=blockIdx.x;
      int by=blockIdx.y;
      int tx=threadIdx.x;
      int ty=threadIdx.y;

     //thread (tx,ty) should work on item helper3 in A,B,C,D

    //for (i=1;i<=2^(EXPO-step)-1;i++)
     //the last processor will not be used so check
      int helper11=pow(2.0,(EXPO+1)*1.0);
    
 
      int helper22=pow(2.0,(EXPO-step+1)*1.0);
        int helper33=pow(2.0,EXPO*1.0)-1;
        printf("step is running: %d \n",step);

     // if(helper3<pow(2.0,(EXPO-step)*1.0)-1)
        //step 1 is special case.
       if(ty!=blockColumn-1&&tx!=blockRow-1)
      {
        // in the formula i will be i=helper3
        /*****calcualte A******************/
        int helper1=helper11;
        int helper2=helper22;
        int flag=0;//special for step1.
        if(step==1)
        {
            helper1=0;
            helper2=0;
            flag=1;
        }

        int helper3=ty*blockColumn+tx+1;
        float ahelperfora1=deviceA[-step+helper1-helper2+2*(helper3)];
        float ahelperfora2=deviceA[-step+helper1-helper2+2*(helper3)-1];
        float bhelperfora1=deviceB[-step+helper1-helper2+2*(helper3)-1];
        deviceA[-1-step+helper1-helper2+helper3+flag*(1+helper33)]=-1*(ahelperfora1)*ahelperfora2/bhelperfora1;

         if(step==1&&tx==1&&ty==0)
         {
            printf("let me see flag: %d \n", flag);
            printf("helper1:%d \n",helper1);
            printf("helper2: %d \n",helper2);
             printf("helper3: %d \n",helper3);
 /*           printf("deviceA[0]:%f \n",deviceA[0]);
              printf("deviceA[1]:%f \n",deviceA[1]);
                printf("deviceB[0]:%f \n",deviceB[0]);*/
            printf("index is :%d \n",-step+helper1-helper2+2*(helper3));
            printf("ahelperfora1 is %f \n",ahelperfora1);
              printf("ahelperfora2 is %f \n",ahelperfora2);
              printf("bhelperfora1 is %f \n",bhelperfora1);
              printf("give me the result: %f",-1*(ahelperfora1)*ahelperfora2/bhelperfora1);
              printf("which one you are calculate tehre? %d \n",-1-step+helper1-helper2+helper3+flag*(1+helper33));


         }

        //*****calculate C******************/
        float chelperforc1=deviceC[-step+helper1-helper2+2*(helper3)];
        float chelperforc2=deviceC[-step+helper1-helper2+2*(helper3)+1];
        float bhelperforc2=deviceB[-step+helper1-helper2+2*(helper3)+1];
        deviceC[-1-step+helper1-helper2+helper3+flag*(1+helper33)]=-1*chelperforc1*chelperforc2/bhelperforc2;

        //calculate B***********************************************//
        float bhelperforb1=deviceB[-step+helper1-helper2+2*(helper3)];
        float bhelperforb2=deviceB[-step+helper1-helper2+2*(helper3)-1];
        float bhelperforb3=deviceB[-step+helper1-helper2+2*(helper3)+1];
        float ahelperforb1=deviceA[-step+helper1-helper2+2*(helper3)];
        float ahelperforb2=deviceA[-step+helper1-helper2+2*(helper3)+1];
        float chelperforb1=deviceC[-step+helper1-helper2+2*(helper3)-1];
        float chelperforb2=deviceC[-step+helper1-helper2+2*(helper3)];
        deviceB[-1-step+helper1-helper2+helper3+flag*(1+helper33)]=bhelperforb1-ahelperforb1/bhelperforb2*chelperforb1-chelperforb2/bhelperforb3*ahelperforb2;

        //calculate D***************************************************//
        float dhelperford1=deviceD[-step+helper1-helper2+2*(helper3)];
        float dhelperford2=deviceD[-step+helper1-helper2+2*(helper3)-1];
        float dhelperford3=deviceD[-step+helper1-helper2+2*(helper3)+1];
        float ahelperford1=deviceA[-step+helper1-helper2+2*(helper3)];
        float bhelperford1=deviceB[-step+helper1-helper2+2*(helper3)-1];
        float bhelperford2=deviceB[-step+helper1-helper2+2*(helper3)+1];
        float chelperford1=deviceC[-step+helper1-helper2+2*(helper3)];
        deviceD[-1-step+helper1-helper2+helper3+flag*(1+helper33)]=dhelperford1-ahelperford1/bhelperford1*dhelperford2-chelperford1/bhelperford2*dhelperford3;
          if(step==1&&tx==0&&ty==0)
      {
        for (int i=0;i<7;i++)
        {
            printf("deviceA in step1: %f \n",deviceA[i]);
         
        }
        for (int i=0;i<7;i++)
        {
            printf("deviceB in step 1: %f \n",deviceB[i]);
         
        }
        for (int i=0;i<7;i++)
        {
            printf("deviceC in step 1: %f \n",deviceC[i]);
         
        }
        for (int i=0;i<7;i++)
        {
            printf("deviceD in step 1: %f \n",deviceD[i]);
         
        }
      }
       if(step==2&&tx==0&&ty==0)
      {
        for (int i=0;i<10;i++)
        {
            printf("deviceA in step2: %f \n",deviceA[i]);
         
        }
        for (int i=0;i<10;i++)
        {
            printf("deviceB in step 2: %f \n",deviceB[i]);
         
        }
        for (int i=0;i<10;i++)
        {
            printf("deviceC in step 2: %f \n",deviceC[i]);
         
        }
        for (int i=0;i<10;i++)
        {
            printf("deviceD in step 2: %f \n",deviceD[i]);
         
        }
      }
       
      
    }
    __syncthreads();
      
    }

    int main()
    {
        
        int m=pow(2,EXPO)-1; //think of our example as n=3 then m will be 7 here
        printf("m value is %d",m);
        int b=1;
        int a=0;
        float delta=(b-a)*1.0/(m+1.0);  //this is correct , think of m as the number of inner 

        float *A;
        float *B;
        float *C;
        float *D;

        //by careful calculation, we figure out we need (2^n-1)*2
        //so the orinal step need to store 2^n-1 value, then step 1 needs 2^(n-1)-1 value and the last one will be 2^1-1 value.
        //so chuck size will be 2^n-1+2^(n-1)-1+....+2-1
        int chunkLength=(pow(2,EXPO)-1)*2;
        int chunkSize=chunkLength*sizeof(float);
        A=(float*)malloc(chunkSize);
        B=(float*)malloc(chunkSize);
        C=(float*)malloc(chunkSize);
        D=(float*)malloc(chunkSize);

        A[0]=0;
        //int vectorLength=EXPO*m;
        printf("m value is %d",m);
        for(int i=1;i<m;i++)
        {
            A[i]=1-delta*delta*0.5*(i+1);
              if(i<7)
            {
                printf("%f \n",A[i]);
            }
                //printf("m value: %d",m);
        }
        //else will be 0
        for(int i=m;i<chunkLength;i++)
        {
          A[i]=0;
        }
        printf("fail here?");
  
        printf("maybe index out of range?");
       

        for(int i=0;i<m;i++)
        {
            B[i]=-2+delta*delta*1.0;
        }
          for(int i=m;i<chunkLength;i++)
        {
          B[i]=0;
        }

        C[m-1]=0;
        for(int i=0;i<m;i++)
        {
            C[i]=1+0.5*delta*delta*(i+1);
        }
        for(int i=m;i<chunkLength;i++)
        {
          C[i]=0;
        }


        D[0]=2*pow(delta,3)+0.5*delta*delta-1;
        for(int i=1;i<m;i++)
        {
            D[i]=2*(i+1)*pow(delta,3);
        }
        for(int i=m;i<chunkLength;i++)
        {
          D[i]=0;
        }


        clock_t begin,end;
        begin=clock();
        //so need to set up different grid dimension for different value of j,
        //when j decrease the size of the thread using will decrease.
        //dim3 dimGrid(1,4); //so we have 4 blocks each block will in charge a,b,c,d respectly.

   

        //http://stackoverflow.com/questions/5029920/how-to-use-2d-arrays-in-cuda
        //according to the above post, the following is the correct way to allocate 2D array on cuda devixe

    /*    float *deviceA, *deviceB, *deviceC, *deviceD;
        size_t pitch;
        cudaMallocPitch((void**)&deviceA,&pitch,m*sizeof(float),EXPO);
        cudaMallocPitch((void**)&deviceB,&pitch,m*sizeof(float),EXPO);
        cudaMallocPitch((void**)&deviceC,&pitch,m*sizeof(float),EXPO);
        cudaMallocPitch((void**)&deviceD,&pitch,m*sizeof(float),EXPO);*/
        float *deviceA, *deviceB, *deviceC, *deviceD;
        cudaMalloc((void**)&deviceA,chunkSize);
        cudaMalloc((void**)&deviceB,chunkSize);
        cudaMalloc((void**)&deviceC,chunkSize);
        cudaMalloc((void**)&deviceD,chunkSize);
        printf("is it still working after cuda Malloc??\n");
        //copy the host vector to device.
        cudaMemcpy(deviceA,A,chunkSize,cudaMemcpyHostToDevice);
        cudaMemcpy(deviceB,B,chunkSize,cudaMemcpyHostToDevice);
        cudaMemcpy(deviceC,C,chunkSize,cudaMemcpyHostToDevice);
        cudaMemcpy(deviceD,D,chunkSize,cudaMemcpyHostToDevice);
        //deviceA, deviceB, deviceC, deviceD is designed to be the global memory of cuda.
        for(int j=1;j<EXPO;j++)
        {
        //the lock size should change, the first step it will need 2^(n-j)-1, so first step will be 3 if n=3
        dim3 dimGrid(1,1);
        int blockRow=pow(2,(EXPO-j)/2);
        printf("blockrow is :%d \n",blockRow);
        int blockColumn=pow(2,EXPO-j-(EXPO-j)/2);
        printf("blockColumn is :%d \n",blockColumn);
        dim3 dimBlock(blockColumn,blockRow);
          //in each step the processor being used should decrease should be 2^(n-j)-1 in jth step
        CalculatePArrayKernel<<<dimGrid,dimBlock>>>(EXPO,j,blockRow,blockColumn,deviceA,deviceB,deviceC,deviceD);


        }
       /* dim3 dimGrid(1,1);
        //int blockRow=pow(2,(EXPO-1)/2);
        //int blockColumn=pow(2,EXPO-1-(EXPO-1)/2);
        dim3 dimBlock(2,2);
        printf("did you run here at least?");
        CalculatePArrayKernel<<<dimGrid,dimBlock>>>(EXPO,2,2,deviceA,deviceB,deviceC,deviceD);*/

        
        //copy the device vector to host
        cudaMemcpy(A,deviceA,chunkSize,cudaMemcpyDeviceToHost);
        cudaMemcpy(B,deviceB,chunkSize,cudaMemcpyDeviceToHost);
        cudaMemcpy(C,deviceC,chunkSize,cudaMemcpyDeviceToHost);
        cudaMemcpy(D,deviceD,chunkSize,cudaMemcpyDeviceToHost);
        
    
        double time_spent;


        end=clock();
        time_spent=(double)(end-begin)/CLOCKS_PER_SEC;
        printf("time is :%f seconds \n",time_spent);

        
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