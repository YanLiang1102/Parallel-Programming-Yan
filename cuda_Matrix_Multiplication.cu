#include <stdio.h>
#include <cuda.h>
#include <time.h>

    double r1();

	__global__ void MatrixMulKernel(float* M,float* N, float* Pd, int blockSize,int loopTimes)
	{
	__shared__ float Ms[16][16];
	__shared__ float Ns[16][16];
	int bx=blockIdx.x;
	int by=blockIdx.y;
	int tx=threadIdx.x;
	int ty=threadIdx.y;

	int Row=by*blockSize+ty;
	int Col=bx*blockSize+tx;

	float sum=0;
	for(int m=0;m<loopTimes;m++)
	{
		Ms[ty][tx]=M[Row*blockSize*loopTimes+(m*blockSize+tx)];
		Ns[ty][tx]=N[Col+(m*blockSize+ty)*blockSize*loopTimes];
		__syncthreads();
		for(int j=0;j<blockSize;j++)
			sum+=Ms[ty][j]*Ns[j][tx];
		__syncthreads();
	}
    Pd[Row*blockSize*loopTimes+Col]=sum;

	}

int main()
{

	int matrixSize=pow(2,8);
	int blockSize=pow(2,4); //the default blockSize I will put as is 16
	int noOfElement=matrixSize*matrixSize;
	float* M;
	float* N;
	float* P;
	M=(float*)malloc(noOfElement*sizeof(float));
	N=(float*)malloc(noOfElement*sizeof(float));
	P=(float*)malloc(noOfElement*sizeof(float));
	clock_t begin, end;


	for(int i=0;i<noOfElement;i++)
	{
		M[i]=r1();
		N[i]=r1();
		P[i]=0.0;
	}
	//start timing after generating the matrix
	begin = clock();

	float* Pd,*Md,*Nd;
    int size=noOfElement*sizeof(float);
	cudaMalloc((void**)&Pd,size);

    //sned M and N to device
    cudaMalloc((void**)&Md,size);
	cudaMemcpy(Md,M,size,cudaMemcpyHostToDevice);
	cudaMalloc((void**)&Nd,size);
	cudaMemcpy(Nd,N,size,cudaMemcpyHostToDevice);
    dim3 dimGrid(matrixSize/blockSize,matrixSize/blockSize);
    dim3 dimBlock(blockSize,blockSize);
    MatrixMulKernel<<<dimGrid,dimBlock>>>(Md,Nd,Pd,blockSize,matrixSize/blockSize);
 

    cudaMemcpy(P,Pd,size,cudaMemcpyDeviceToHost);


	cudaFree(Pd);

	
    double time_spent;

    
/* here, do your time-consuming job */
    end = clock();
    time_spent = (double)(end - begin) / CLOCKS_PER_SEC;
    printf("time Spend for matrix size: (%d,%d), with blockSize: %d is :%f \n",matrixSize,matrixSize,blockSize,time_spent);
   

    printf("The following are the first 100 reuslt from the matrix multiplication:\n");
    //print out first 100 result.
	for(int i=0;i<100;i++)
	{
		printf("result: %f \n",P[i]);
	}

	return 0;
}

double r1()
{
    return -1.0*(double)rand() / (double)RAND_MAX ;
}