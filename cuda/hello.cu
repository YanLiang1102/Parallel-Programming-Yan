#include <stdio.h>
#include <cuda.h>
 
const int N = 7; 
const int blocksize = 7; 
 
__global__ void hello(char *a, int *b) 
{
        int idx = blockIdx.x * blockDim.x + threadIdx.x;        // Finds the thread_id
        //a[threadIdx.x] += b[threadIdx.x];
        a[idx] += b[idx];
        printf("yan yan yan! \n");
}
 
int main()
{
        char a[N] = "Hello ";
  int b[N] = {15, 10, 6, 0, -11, 1};
 
        char *ad;
        int *bd;
        const int csize = N*sizeof(char);
        const int isize = N*sizeof(int);
 
        printf("The original string: %s\n", a);
 
        cudaMalloc( (void**)&ad, csize ); 
        cudaMalloc( (void**)&bd, isize ); 
        cudaMemcpy( ad, a, csize, cudaMemcpyHostToDevice ); 
        cudaMemcpy( bd, b, isize, cudaMemcpyHostToDevice ); 
        
        dim3 Block( 1, 1 );                     // Number of threads per block
        dim3 Grid( blocksize, 1 );              // Number of thread blocks
        
        hello<<<Grid, Block>>>(ad, bd);
        cudaMemcpy( a, ad, csize, cudaMemcpyDeviceToHost ); 
        cudaFree( ad );
        cudaFree( bd );
        printf("The modified string: %s\n", a);
               return 0;
}

