#include <stdio.h>
#include <cuda.h>


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
}

int main()
{
	int Width=2;
/*	float* M;
	float* N;
	float* P;
	M=malloc(4*sizeof(float));
	N=malloc(4*sizeof(float));
	P=malloc(4*sizeof(float));*/
	float M[2],N[2],P[2];

	for(int i=0;i<4;i++)
	{
		M[i]=i+1.0;
		N[i]=i+2.0;
		P[i]=0.0;
	}

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
	}


	return 0;
}