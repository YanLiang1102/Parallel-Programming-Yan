    #include <stdio.h>
    #include <cuda.h>
    #include <time.h>
    #define EXPO 9
   
    //the right way to add in cuda driver if you have an gpu
    //http://askubuntu.com/questions/451221/ubuntu-14-04-install-nvidia-driver




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

    //this is the kernel to calculate the P=(a,b,c,d)
    //need to pass in the step which is j, and then figure out which thread to work on
    //the calculation in (2^j,2*2^j,3*2^j....)
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
    }

        __syncthreads();
    }

    int main()
    {
        
        int m=pow(2,EXPO)-1; //think of our example as n=3 then m will be 7 here
        /*printf("m value is %d",m);*/
        int b=1;
        int a=0;
        float delta=(b-a)*1.0/(m+1.0);  //this is correct , think of m as the number of inner 

        float *A;
        float *B;
        float *C;
        float *D;
        float *FinalX;

        //by careful calculation, we figure out we need (2^n-1)*2
        //so the orinal step need to store 2^n-1 value, then step 1 needs 2^(n-1)-1 value and the last one will be 2^1-1 value.
        //so chuck size will be 2^n-1+2^(n-1)-1+....+2-1
        //int chunkLength=(pow(2,EXPO)-1)*2;
        //ad one for the extra thread that never going to use, so in this way it will not be out of index
        int finalLengthX=(int)pow(2,EXPO)+1;
        int chunkLength=(pow(2,EXPO)-1)*2+1;
        int chunkSize=chunkLength*sizeof(float);
        A=(float*)malloc(chunkSize);
        B=(float*)malloc(chunkSize);
        C=(float*)malloc(chunkSize);
        D=(float*)malloc(chunkSize);
        FinalX=(float*)malloc(finalLengthX*sizeof(float));

        A[0]=0;
        //int vectorLength=EXPO*m;
     
        for(int i=1;i<m;i++)
        {
            A[i]=1-delta*delta*0.5*(i+1);
        }
        //else will be 0
        for(int i=m;i<chunkLength;i++)
        {
          A[i]=0;
        }

        for(int i=0;i<m;i++)
        {
            B[i]=-2+delta*delta*1.0;
        }
          for(int i=m;i<chunkLength;i++)
        {
          B[i]=0;
        }

        C[m-1]=0;
        for(int i=0;i<m-1;i++)
        {
            C[i]=1+0.5*delta*delta*(i+1);
        }
        for(int i=m;i<chunkLength;i++)
        {
          C[i]=0;
        }


       /* D[0]=2*delta*delta*delta+0.5*delta*delta-1;*/
        for(int i=0;i<m-1;i++)
        {
            D[i]=2*(i+1)*pow(delta,3);
        }
        D[m-1]=2*m*delta*delta*delta-1+3.5*delta*delta;
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

        float *deviceA, *deviceB, *deviceC, *deviceD,*deviceFinalX;
        cudaMalloc((void**)&deviceA,chunkSize);
        cudaMalloc((void**)&deviceB,chunkSize);
        cudaMalloc((void**)&deviceC,chunkSize);
        cudaMalloc((void**)&deviceD,chunkSize);
        cudaMalloc((void**)&deviceFinalX,finalLengthX*sizeof(float));

       
        //copy the host vector to device.
        cudaMemcpy(deviceA,A,chunkSize,cudaMemcpyHostToDevice);
        cudaMemcpy(deviceB,B,chunkSize,cudaMemcpyHostToDevice);
        cudaMemcpy(deviceC,C,chunkSize,cudaMemcpyHostToDevice);
        cudaMemcpy(deviceD,D,chunkSize,cudaMemcpyHostToDevice);
        //deviceA, deviceB, deviceC, deviceD is designed to be the global memory of cuda.
        //forward
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
        CalculatePArrayKernel<<<dimGrid,dimBlock>>>(j,blockRow,blockColumn,deviceA,deviceB,deviceC,deviceD);

        }


        //backward
        //copy the device vector to host
        cudaMemcpy(A,deviceA,chunkSize,cudaMemcpyDeviceToHost);
        cudaMemcpy(B,deviceB,chunkSize,cudaMemcpyDeviceToHost);
        cudaMemcpy(C,deviceC,chunkSize,cudaMemcpyDeviceToHost);
        cudaMemcpy(D,deviceD,chunkSize,cudaMemcpyDeviceToHost);
        int lastIndex=(int)pow(2,EXPO+1)-EXPO-3;
        float initialValue=D[lastIndex]/B[lastIndex];
        FinalX[0]=0;
        FinalX[(int)pow(2,EXPO-1)]=initialValue;
        printf("the value in the middle is: %f and this suppose to close to 0.5 when n goes big! \n",FinalX[(int)pow(2,EXPO-1)]);

         cudaMemcpy(deviceFinalX,FinalX,finalLengthX*sizeof(float),cudaMemcpyHostToDevice);
        for(int k=EXPO-1;k>=1;k--)
        {
          //so the most one will use 2^(n-k) variable will be covered!
        dim3 dimGrid(1,1);
        int blockRow=pow(2,(EXPO-k)/2);
        int blockColumn=pow(2,EXPO-k-(EXPO-k)/2);
        dim3  dimBlock(blockColumn,blockRow);
        
        BackwardKernel<<<dimGrid,dimBlock>>>(k,blockRow,blockColumn,deviceA,deviceB,deviceC,deviceD,deviceFinalX,initialValue);


        }


        cudaMemcpy(FinalX,deviceFinalX,finalLengthX*sizeof(float),cudaMemcpyDeviceToHost);
          printf(" \n");
          printf(" A \n");
        for(int i=0;i<chunkLength;i++)
        {   
            if(i%8==0)
            {
                printf("\n");
            }
            printf("%f ",A[i]);
        }
             printf(" \n");
            printf(" B \n");
        for(int i=0;i<chunkLength;i++)
        {
              if(i%8==0)
            {
                printf("\n");
            }
            printf("%f ",B[i]);
        }
            printf(" \n");
            printf(" C \n");
        for(int i=0;i<chunkLength;i++)
        {
              if(i%8==0)
            {
                printf("\n");
            }
            printf("%f ",C[i]);
        }
            printf(" \n");
            printf(" D \n");
        for(int i=0;i<chunkLength;i++)
        {
              if(i%8==0)
            {
                printf("\n");
            }
            printf("%f ",D[i]);
        }

        
        double time_spent;


        end=clock();
        time_spent=(double)(end-begin)/CLOCKS_PER_SEC;
   
          
          printf("\n the following are the solutions.");
          for(int i=0;i<finalLengthX;i++)
          {
            if(i%8==0)
            {
                printf("\n");
            }
            printf("%f ",FinalX[i]);
          }
        printf("\n time used to calculate this is :%f seconds \n",time_spent);
       
        
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
