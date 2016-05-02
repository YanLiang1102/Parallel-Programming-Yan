#include <stdio.h>
#include <cuda.h>
#include <time.h>
#define GAMMA 0.5

double r2();
__global__ void JORkernel(double *cudaM,double *cudaX, int dim)
{
        //int idx = blockIdx.x * blockDim.x + threadIdx.x;        // Finds the thread_id
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
        int j;
        //bool localFlag; // idea is to "and" all the flag and see any false 
       // printf("bx: %d \n",bx);
       // printf("by: %d \n",by);
       // printf("tx: %d \n",tx);
       // printf("ty: %d \n",ty);

        //double temp; //this temp is going to check with the old x and see if closer enough if not it will be copied into cudaX;

       int ind=temp1*blocktotal+temp2;
       if(ind<dim)
     { 
       //printf("%d \n",ind);
      //put JOR formula here
     	//b is 0 all the time so we don't need to consider about it so far
     	int tempi=ind%dim;
     	double sum=0;
     	for(j=0;j<dim;j++)
     	{
     		if(j!=tempi)
     		{
     			sum=sum+cudaM[tempi*dim+j]*cudaX[j];
     		}
     	}
     	cudaX[ind]=(1-GAMMA)*cudaX[ind]-GAMMA/cudaM[tempi*dim+tempi]*sum; //temp is the updated x
        //now comapre
/*        if(temp-cudaX[ind]>=0.01||cudaX[ind]-temp>=0.01)
        {
        	localFlag=false;
        }
        else
        {
        	localFlag=true;
        }
        myGlobalFlag=myGlobalFlag && localFlag;*/
     }

     __syncthreads();
     //wait for all the threads to finish, this is not going to work because it only snyc threads inside of one block.
}

int main(int argc, char *argv[])
{
   
   if( argc == 2 ) {
      printf("The matrix dimension is %s\n", argv[1]);
   }
   else if( argc > 2 ) {
      printf("Too many arguments supplied.\n");
   }
   else {
      printf("One argument expected.\n");
   }

        int i;
        int j;
        int dim=atoi(argv[1]);
        double *matrix;
        double *x;
        double *previousx; // to install the previous x for compare purpose
        int loopCount=0; //use to see how many iteration we need to get the correct result;
        double tolerance=0.001;
       /* double *b;*/
        matrix=(double*) malloc(dim*dim*sizeof(double));
      /*  b=(double*) malloc(dim*sizeof(double));*/
        x=(double*) malloc(dim*sizeof(double));
        previousx=(double*) malloc(dim*sizeof(double));
        //the diagonal dominated matrix will be automatically be not singular!!
      for(i=0;i<dim;i++)
      {
        double rowSum=0.0;
        for(j=0;j<dim;j++)
        {
            
            matrix[i*dim+j]=r2();
            rowSum=matrix[i*dim+j]+rowSum;
        }
        matrix[i*dim+i]=rowSum;
      }
      //x will all be initilized to be 1
      for(i=0;i<dim;i++)
      {
      	x[i]=1.0;
      	previousx[i]=1.0;
      	//b[i]=0.0;  //make b to be 0 as initial then easy to check that the value x should goes to 0;
      }
      
  //print the matrix out to check
     // for(i=0;i<dim;i++)
     // {
       // for(j=0;j<dim;j++)
      //  {
        //  printf("%lf ",matrix[i*dim+j]);
       // }
       // printf("\n");
     // }
      double *cudaM; //prepare for cuda global memory
      double *cudaX;
   /*   double *cudaB;*/
      int xsize=dim*sizeof(double);
      int msize=dim*dim*sizeof(double);
      cudaMalloc((void**)&cudaM,msize);
      cudaMalloc((void**)&cudaX,xsize);
    /*  cudaMalloc((void**)&cudaB,xsize);*/ //b have the same size with x



     //start timing here
      clock_t begin,end;
        begin=clock();
      cudaMemcpy(cudaM,matrix,msize,cudaMemcpyHostToDevice);
      cudaMemcpy(cudaX,x,xsize,cudaMemcpyHostToDevice);
  /*    cudaMemcpy(cudaB,b,xsize,cudaMemcpyHostToDevice);*/

     // cudaMalloc( (void**)&ad, csize );
     // cudaMalloc( (void**)&bd, isize );
     // cudaMemcpy( ad, a, csize, cudaMemcpyHostToDevice );
     // cudaMemcpy( bd, b, isize, cudaMemcpyHostToDevice );
      int blocksize=16;
      int gridsize= dim/256+1; //make the gridsize to be an ro  like (1,2)
      dim3 Grid( 1, gridsize);                   // Number of threads per block
      dim3 Block( blocksize,blocksize);              // Number of thread blocks

      bool stopFlag=false;
      while (!stopFlag)
      {
      loopCount=loopCount+1;
      JORkernel<<<Grid, Block>>>(cudaM,cudaX,dim);
      cudaMemcpy( x, cudaX, xsize, cudaMemcpyDeviceToHost);
      //comapre new x with previous x
      for(i=0;i<dim;i++)
      {
      	if((x[i]-previousx[i]>=tolerance)||(previousx[i]-x[i])>=tolerance) //check if the current value and previous value is close enough
      		//if not we need to keep going
      	{
      		for(j=0;j<dim;j++)
      		{
      			previousx[j]=x[j];
      		}
      		stopFlag=false;
      		//don't need to copy to cuda again since it will be the same cudaX.
      		//JORKernel<<<Grid,Block>>>(cudaM,cudaX,dim);
      		break;
      	}
        if(i==dim-1) //this means there is no break in the middle at all
       {
      	stopFlag=true;
       }

      } 
     }
       double time_spent;
        end=clock();
       time_spent=(double)(end-begin)/CLOCKS_PER_SEC;
     printf("matrix size: %d-iteration times: %d-error tolerance set to:%lf \n",dim,loopCount,tolerance);
     printf("time spent:%lf seconds \n",time_spent);  
    for(i=0;i<dim;i++)
      {
       if(i%10==0)
      {
       printf("\n");
       }
       printf("[%d]:%lf ",i,x[i]);
      }
      cudaFree(cudaX); 
      cudaFree(cudaM);
      
     // printf("The modified string: %s\n", a);
     return 0;
}

double r2()
{
    return (double)rand() / (double)RAND_MAX ;
}







