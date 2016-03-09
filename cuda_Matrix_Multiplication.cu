#include <stdio.h>
#include <cuda.h>

/*
__global__ void MatrixMulKernel(float* Md, float* Nd,float* Pd,int Width)
{
	float Pvalue=0;

	for(int k=0;k<Width;++k)
	{
		float Melement=Md[threadIdx.y*Width+k];
		float Nelement=Nd[k*Width+threadIdx.x];
		Pvalue+=Melement*Nelement;
	}

	Pd[threadIdx.y*Width+threadIdx.x]=Pvalue;
}*/

	__global__ void MatrixMulKernel(float* M,float* N, float* Pd, int blockSize,int loopTimes)
	{
	__shared__ float Ms[1][1];
	__shared__ float Ns[1][1];
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

	int matrixSize=2;//pow(2,8);
	int blockSize=1;//pow(2,4);
	//int noOfElement=matrixSize*matrixSize;
/*	float* M;
	float* N;
	float* P;
	M=malloc(4*sizeof(float));
	N=malloc(4*sizeof(float));
	P=malloc(4*sizeof(float));*/
	float M[matrixSize],N[matrixSize],P[matrixSize];

	for(int i=0;i<matrixSize*matrixSize;i++)
	{
		M[i]=i+1.0;
		N[i]=i+2.0;
		P[i]=0.0;
	}

	float* Pd;
    int size=matrixSize*matrixSize*sizeof(float);
	cudaMalloc((void**)&Pd,size);
/*
	int size=Width*Width*sizeof(float);
    float* Md, *Nd, *Pd;

    cudaMalloc((void**)&Md,size);
	cudaMemcpy(Md,M,size,cudaMemcpyHostToDevice);
	cudaMalloc((void**)&Nd,size);
	cudaMemcpy(Nd,N,size,cudaMemcpyHostToDevice);
	cudaMalloc((void**)&Pd,size);

    dim3 dimGrid(1,1);
    dim3 dimBlock(Width,Width);
    MatrixMulKernel<<<dimGrid,dimBlock>>>(Md,Nd,Pd,Width);

    cudaMemcpy(P,Pd,size,cudaMemcpyDeviceToHost);

	cudaFree(Md);
	cudaFree(Nd);
	cudaFree(Pd);

	for(int i=0;i<4;i++)
	{
		printf("result: %f \n",P[i]);
	}*/
    dim3 dimGrid(matrixSize/blockSize,matrixSize/blockSize);
    dim3 dimBlock(blockSize,blockSize);
    MatrixMulKernel<<<dimGrid,dimBlock>>>(M,N,Pd,blockSize,matrixSize/blockSize);
    __syncthreads();

    cudaMemcpy(P,Pd,size,cudaMemcpyDeviceToHost);


	cudaFree(Pd);

	for(int i=0;i<matrixSize*matrixSize;i++)
	{
		printf("result: %f \n",P[i]);
	}


	return 0;
}