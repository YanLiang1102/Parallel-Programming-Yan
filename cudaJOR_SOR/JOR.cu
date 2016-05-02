#include <stdio.h>
#include <cuda.h>

double r2();
__global__ void JORkernel(double *cudaM,int dim)
{
        //int idx = blockIdx.x * blockDim.x + threadIdx.x;        // Finds the thread_id
        int blocksize=16;
        int gridsize=gridDim.x; //this will always be 1
       // int gridsize2=gridDim.x;
       // printf("gridsize: %d %d\n", gridsize,gridsize2);
       
        int bx=blockIdx.x;
        int by=blockIdx.y;
        int tx=threadIdx.x;
        int ty=threadIdx.y;
        
        int blocktotal=blocksize*blocksize;
        int temp1=by*gridsize+bx;
        int temp2=ty*blocksize+tx;
       // printf("bx: %d \n",bx);
       // printf("by: %d \n",by);
       // printf("tx: %d \n",tx);
       // printf("ty: %d \n",ty);



       int ind=temp1*blocktotal+temp2;
       if(ind<dim)
     { 
        printf("%d \n",ind);
     }
}

int main()
{
        int i;
        int j;
        int dim=1000;
        double *matrix;
        matrix=(double*) malloc(dim*dim*sizeof(double));

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
      int msize=dim*dim*sizeof(double);
      cudaMalloc((void**)&cudaM,msize);
      cudaMemcpy(cudaM,matrix,msize,cudaMemcpyHostToDevice);

     // cudaMalloc( (void**)&ad, csize );
     // cudaMalloc( (void**)&bd, isize );
     // cudaMemcpy( ad, a, csize, cudaMemcpyHostToDevice );
     // cudaMemcpy( bd, b, isize, cudaMemcpyHostToDevice );
      int blocksize=16;
      int gridsize= dim/256+1; //make the gridsize to be an ro  like (1,2)
      dim3 Grid( 1, gridsize);                   // Number of threads per block
      dim3 Block( blocksize,blocksize);              // Number of thread blocks
      JORkernel<<<Grid, Block>>>(cudaM,dim);
      //cudaMemcpy( a, ad, csize, cudaMemcpyDeviceToHost );
      cudaFree( cudaM );
      
     // printf("The modified string: %s\n", a);
      return 0;
}

double r2()
{
    return (double)rand() / (double)RAND_MAX ;
}






