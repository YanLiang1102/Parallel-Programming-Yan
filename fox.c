#include "mpi.h"
#include <stdio.h>
#include <sys/time.h>
#include <time.h>
#include <stdlib.h>
#include <stdbool.h>
#include <math.h>
//in order to compile code with reference to math.h you need -lm at the end

double r1();
double r2();

int main(int argc, char* argv[])
{
	int q; //q*q will be all the process we have
	int mypid,mysize;
    int i,j,k,l;
	int my_row,my_col;
	int myIdInRowGroup, myIdInColGroup;
    int rows=4;
    int cols=4;
    int blockSize; //this will store the size of each submatrix that is on each process
    double *localSubmatrixM;
    double *localSubmatrixN;
    double *localTempM;
    double *localTempN;
	MPI_Init(&argc,&argv);
	MPI_Comm_size(MPI_COMM_WORLD,&mysize);
	MPI_Comm_rank(MPI_COMM_WORLD,&mypid);
	q=(int)sqrt(mysize);
    //this will will be submatrix on each process that store the Result.
    double **subResult;
    double **M;
    double **N;
    double *bigArrayForM;
    double *bigArrayForN;
    
	//printf("this is my q: %d",q);
	MPI_Comm my_row_comm;
	MPI_Comm my_col_comm;


    
    //mypid is the pif in mpi_Comm_world
    my_row=mypid/q;
    my_col=mypid%q;
    blockSize=rows/q;
	MPI_Comm_split(MPI_COMM_WORLD,my_row,mypid,&my_row_comm);
    MPI_Comm_split(MPI_COMM_WORLD,my_col,mypid,&my_col_comm);
    double randomNumber;
   
   //to make the subresult matrix that reside on each process.
    subResult=(double **) malloc(blockSize*sizeof(double*));
    for(l=0;l<blockSize;l++)
    {
        subResult[l]=(double *)malloc(blockSize*sizeof(double));
    }
    for(i=0;i<blockSize;i++){
         for(j=0;j<blockSize;j++)
         {
            subResult[i][j]=0;
         }           
    }

    localSubmatrixM=(double *)malloc(blockSize*blockSize*sizeof(double));
    localSubmatrixN=(double *)malloc(blockSize*blockSize*sizeof(double));
    localTempM=(double *)malloc(blockSize*blockSize*sizeof(double));
    localTempN=(double *)malloc(blockSize*blockSize*sizeof(double));
  /*  if(mypid<q*q)
    {
    	MPI_Comm_rank(my_row_comm,&myIdInRowGroup);
    	MPI_Comm_rank(my_col_comm,&myIdInColGroup);
    	printf("my comm world Id: %d \n",mypid);
    	printf("my row Id: %d \n",myIdInRowGroup);
    	printf("my col Id: %d \n",myIdInColGroup);
    	printf("\n");
    }*/
       
        if(mypid==0) //make the first process generete the M,N matrix but not timing this, and make process0 scatter the result but not timing the scatter time.
        {
          
          int step;
          //just need to malloc in proceess1 other process don't need to malloc this.
          bigArrayForM=(double*) malloc(rows*rows*sizeof(double));
          bigArrayForN=(double*) malloc(rows*rows*sizeof(double));
          
            M=(double **) malloc(rows*sizeof(double *));
            for(i=0;i<rows;i++)
            {
                M[i]=(double *) malloc(cols*sizeof(double));
            }
            N=(double **) malloc(rows*sizeof(double *));
            for(i=0;i<rows;i++)
            {
                N[i]=(double *) malloc(cols*sizeof(double));
            }

             for(i=0;i<rows;i++){
                 for(j=0;j<cols;j++)
                 {
                    N[i][j]=r1()+r2();
                    printf(" N%lf ",N[i][j]);
                 }
                 printf("\n"); 
             }
              for(i=0;i<rows;i++){
                 for(j=0;j<cols;j++)
                 {
                    M[i][j]=r1()+r2();
                    printf(" M%lf ",M[i][j]);

                 }
                  printf("\n"); 
             }
             //this will put M,N in contiguous manner, so we can send them off to other process using MPI_Scatter, this part is pretty tricky but beautiful.
            for(step=0;step<q*q;step++)
            {
                for(i=0;i<blockSize*blockSize;i++)
                {
                    bigArrayForM[blockSize*blockSize*step+i]=M[blockSize*(step/q)+i/q][blockSize*(step%q)+i%q];
                }
            }
              for(step=0;step<q*q;step++)
            {
                for(i=0;i<blockSize*blockSize;i++)
                {
                   bigArrayForN[blockSize*blockSize*step+i]=N[blockSize*(step/q)+i/q][blockSize*(step%q)+i%q];
                }
            }  

            //scatter M and N
            MPI_Scatter(bigArrayForM,blockSize*blockSize,MPI_DOUBLE,localSubmatrixM,blockSize*blockSize,MPI_DOUBLE,0,MPI_COMM_WORLD);
            MPI_Scatter(bigArrayForN,blockSize*blockSize,MPI_DOUBLE,localSubmatrixN,blockSize*blockSize,MPI_DOUBLE,0,MPI_COMM_WORLD);
           /* for(i=0;i<blockSize*blockSize;i++)
            {
                printf("%lf in process ID: %d: \n",localSubmatrixM[i],mypid);
            }*/
           //the above block is the most delicate part to make it successful!

        }
        else
        {

            MPI_Scatter(bigArrayForM,blockSize*blockSize,MPI_DOUBLE,localSubmatrixM,blockSize*blockSize,MPI_DOUBLE,0,MPI_COMM_WORLD);
            MPI_Scatter(bigArrayForN,blockSize*blockSize,MPI_DOUBLE,localSubmatrixN,blockSize*blockSize,MPI_DOUBLE,0,MPI_COMM_WORLD);
    
          /*  for(i=0;i<blockSize*blockSize;i++)
            {
                printf("%lf in process ID: %d: \n",localSubmatrixM[i],mypid);
            }*/
        }
       
       //beginning of the fox algorithms, call MPI_BARRIER make sure each process is on the same page
        MPI_Comm_rank(my_row_comm,&myIdInRowGroup);
        MPI_Comm_rank(my_col_comm,&myIdInColGroup);

        //we need to q step to finish the calculation, which q is how many process we have on each row, and also it is how many process we have on each column.
        //now for each of the process, do the regular matrix multiplication
        MPI_Barrier(MPI_COMM_WORLD);
        int transferStep;
       
        
        for(transferStep=0;transferStep<q;transferStep++)
        {
          
            //BroadCast M and keep N as what it is. I think for N we don't need a localTempNForIt, it should record all the data by itself
              if(myIdInRowGroup==((mypid/q)+transferStep)%q)
              {
                localTempM=localSubmatrixM;
               MPI_Bcast(localTempM,blockSize*blockSize,MPI_DOUBLE,myIdInRowGroup,my_row_comm);
               
              }
               else
               {
                MPI_Bcast(localTempM,blockSize*blockSize,MPI_DOUBLE,((mypid/q)+transferStep)%q,my_row_comm);
               }
         /*   if(mypid/q==1)
            {
                printf("this is the local temp pid %d in step %d: \n",mypid,transferStep);
                for(i=0;i<blockSize*blockSize;i++)
                {
                    printf(" %lf ",localTempM[i]);
                }
                printf("\n");
            }*/
        /*    if(mypid/q==0)
            {
                printf("this is the local temp pid %d in step %d: \n",mypid,transferStep);
                for(i=0;i<blockSize*blockSize;i++)
                {
                    printf(" %lf ",localSubmatrixN[i]);
                }
                printf("\n");

            }*/

           //now make serialize multiplication
      /*     for(i=0;i<blockSize;i++)
              {
                
                for(j=0;j<blockSize;j++)
                {*/
                    //so need the ith row of subA and jth col of subB multiply together
                  for(i=0;i<blockSize*blockSize;i++)
                  {
                    
                        for(l=0;l<blockSize;l++)
                        {
                            //this step is very delicate.
                  
                         subResult[i/q][i%q] =subResult[i/q][i%q]+localTempM[(i/q)*blockSize+l]*localSubmatrixN[l*blockSize+(i%q)];
                         /* printf(" %lf \n",subResult[i/q][i%q]);*/
                        }
                    
                    
                  }
             
            /*    }
              }*/
              


        if(mypid==0)
        {
            printf("Here is the result: \n");
        for(i=0;i<blockSize;i++)
        {
            for(j=0;j<blockSize;j++)
            {
               printf(" %lf ",subResult[i][j]);
            }
            printf("\n");
        }
        }

    /*             if(mypid==0)
        {
            printf("Here is the result: \n");
        for(i=0;i<blockSize;i++)
        {
            for(j=0;j<blockSize;j++)
            {
               printf(" %lf ",subResult[i][j]);
            }
            printf("\n");
        }
        }*/
            //for matrix N we can use BroadCasting, we have to use send receive, since now the all the process in the same column get the same data
            if(myIdInColGroup!=0)
            {
                //0 here is the tag for send and receive
            MPI_Send(localSubmatrixN,blockSize*blockSize,MPI_DOUBLE,myIdInColGroup-1,0,my_col_comm);
             }
             else
            {
             MPI_Send(localSubmatrixN,blockSize*blockSize,MPI_DOUBLE,blockSize-1,0,my_col_comm);
            }
            //now need to receive
            if(myIdInColGroup!=q-1)
            {
                MPI_Recv(localSubmatrixN,blockSize*blockSize,MPI_DOUBLE,myIdInColGroup+1,0,my_col_comm,MPI_STATUS_IGNORE);
            }
            else
            {
                MPI_Recv(localSubmatrixN,blockSize*blockSize,MPI_DOUBLE,0,0,my_col_comm,MPI_STATUS_IGNORE);
            }
 
           MPI_Barrier(MPI_COMM_WORLD);
        }
        //ok now, after all the multiplication, we should print out the local result
        MPI_Barrier(MPI_COMM_WORLD);

       /* if(mypid==0)
        {
            printf("Here is the result: \n");
        for(i=0;i<blockSize;i++)
        {
            for(j=0;j<blockSize;j++)
            {
               printf(" %lf ",subResult[i][j]);
            }
            printf("\n");
        }
        }*/

    	
 /*   	if(myIdInRowGroup==0)
    	{
           srand(time(NULL)+mypid);
           randomNumber=r2();
           
    	   printf("grouprow: %d ,the number I generated is : %lf \n",my_row,randomNumber);
           MPI_Bcast(&randomNumber,1,MPI_DOUBLE,0,my_row_comm);
           
    	}
    	else
    	{
    		MPI_Bcast(&randomNumber,1,MPI_DOUBLE,0,my_row_comm);
    	}
    	if(myIdInRowGroup!=0)
    	{
    	printf("my rowGroup is : %d the number I have is : %lf \n",my_row,randomNumber);
    	
        }
*/


    MPI_Finalize();
    exit(0);

}

 //this is the way to generate random number between 0 and 1
double r1()
{
    return -1.0*(double)rand() / (double)RAND_MAX ;
}
   //this is the way to generate random number between 0 and 1
double r2()
{
    return (double)rand() / (double)RAND_MAX ;
}

