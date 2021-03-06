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
    int rows=pow(2,10);
    int cols=pow(2,10);
    int blockSize; //this will store the size of each submatrix that is on each process
    double *localSubmatrixM;
    double *localSubmatrixN;
    double **localM;
    double **localN;
    double **subMatrixToSendM;  // this is the data to be scattered to each process
    double **subMatrixToSendN;
    double **localSubmatrixNNew; // this is the data to be received on the local.
    double **localSubmatrixMNew;
    double **localTempMNew;
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
    double **R;
    double *bigArrayForM;
    double *bigArrayForN;
    double sstart,sfinish,pstart,pfinish,dstart,dfinish;//store serialized multiplication and parallel multiplication time and distribution time of the data.
    
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
    localM=(double **)malloc(blockSize*sizeof(double *));
    localN=(double **)malloc(blockSize*sizeof(double *));
    localTempMNew=(double **)malloc(blockSize*sizeof(double *));
    for(i=0;i<blockSize;i++)
    {
      localTempMNew[i]=(double*)malloc(blockSize*sizeof(double));
    }
    for(i=0;i<blockSize;i++)
    {
      localM[i]=(double *)malloc(blockSize*sizeof(double));
      localN[i]=(double *)malloc(blockSize*sizeof(double));
    }
    for(i=0;i<blockSize;i++)
    {
      for(j=0;j<blockSize;j++)
      {
        localM[i][j]=0;
        localN[i][j]=0;
      }
    }
    //trying to change the way of doing this, trying to scatetr the big matrix row by row hopefully
    subMatrixToSendM=(double **)malloc(blockSize*sizeof(double *));
    subMatrixToSendN=(double **)malloc(blockSize*sizeof(double *));
    for(i=0;i<blockSize;i++)
    {
      subMatrixToSendM[i]=(double *)malloc(blockSize*sizeof(double));
      subMatrixToSendN[i]=(double *)malloc(blockSize*sizeof(double));
    }
    for(i=0;i<blockSize;i++)
    {
      for(j=0;j<blockSize;j++)
      {
        subMatrixToSendM[i][j]=0;
        subMatrixToSendN[i][j]=0;
      }
    }

    localSubmatrixMNew=(double **)malloc(blockSize*sizeof(double *));
    localSubmatrixNNew=(double **)malloc(blockSize*sizeof(double *));
    for(i=0;i<blockSize;i++)
    {
      localSubmatrixMNew[i]=(double *)malloc(blockSize*sizeof(double));
      localSubmatrixNNew[i]=(double *)malloc(blockSize*sizeof(double));
    }
    for(i=0;i<blockSize;i++)
    {
      for(j=0;j<blockSize;j++)
      {
        localSubmatrixMNew[i][j]=0;
        localSubmatrixNNew[i][j]=0;
      }
    }
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
                    //printf(" N%lf ",N[i][j]);
                 }
                 //printf("\n"); 
             }
              for(i=0;i<rows;i++){
                 for(j=0;j<cols;j++)
                 {
                    M[i][j]=r1()+r2();
                    //printf(" M%lf ",M[i][j]);

                 }
                  //printf("\n"); 
             }
            //this only allocate on first process to test the time of the serialized multiplication
            R=(double **) malloc(rows*sizeof(double *));
            for(i=0;i<rows;i++)
            {
                R[i]=(double *) malloc(cols*sizeof(double));
            }
             for(i=0;i<rows;i++){
                 for(j=0;j<cols;j++)
                 {
                    R[i][j]=0.0;

                 }
             }
             sstart=MPI_Wtime();
              for(i=0;i<rows;i++)
              {
                for(j=0;j<cols;j++)
                {
                  for(k=0;k<cols;k++) //here can be cols or rows it does not matter ,since teh matrix is a square here
                  {
                    R[i][j]=R[i][j]+M[i][k]*N[k][j];
                    
                  }
                  //printf(" %lf ",R[i][j]);
                }
                //printf("\n");
              }
              sfinish=MPI_Wtime();
              //after caculate the serilized version free the memory,but still need to keep it there for testing.
          /*     for(i=0;i<rows;i++)
            {
                free(R[i]);
            }
            free(R);*/
            //free the memory

              printf("time took for serialized multiplication of size %d * %d matrix is: %lf \n",rows,cols,sfinish-sstart);
             //this will put M,N in contiguous manner, so we can send them off to other process using MPI_Scatter, this part is pretty tricky but beautiful.
              dstart=MPI_Wtime();
            for(step=0;step<q*q;step++)
            {
                for(i=0;i<blockSize*blockSize;i++)
                {
                    bigArrayForM[blockSize*blockSize*step+i]=M[blockSize*(step/q)+i/blockSize][blockSize*(step%q)+i%blockSize];
                }
            }
              for(step=0;step<q*q;step++)
            {
                for(i=0;i<blockSize*blockSize;i++)
                {
                   bigArrayForN[blockSize*blockSize*step+i]=N[blockSize*(step/q)+i/blockSize][blockSize*(step%q)+i%blockSize];
                }
            }  
        /*     for(step=0;step<q*q;step++)
             {
              for(i=0;i<blockSize;i++)
              {
                for(j=0;j<blockSize;j++)
                {
                  subMatrixToSendM[i][j]=M[blockSize*(step/q)+i][blockSize*(step%q)+j];
                }
              }
             }
            for(step=0;step<q*q;step++)
             {
              for(i=0;i<blockSize;i++)
              {
                for(j=0;j<blockSize;j++)
                {
                  subMatrixToSendN[i][j]=N[blockSize*(step/q)+i][blockSize*(step%q)+j];
                }
              }
             }*/

          /*  for(i=0;i<q;i++)
            {
              MPI_Scatter(subMatrixToSendM[i],blockSize,MPI_DOUBLE,localSubmatrixMNew[i],blockSize,MPI_DOUBLE,0,MPI_COMM_WORLD);
              MPI_Scatter(subMatrixToSendN[i],blockSize,MPI_DOUBLE,localSubmatrixNNew[i],blockSize,MPI_DOUBLE,0,MPI_COMM_WORLD);
            }*/
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
       /*   for(i=0;i<q;i++)
            {
              MPI_Scatter(subMatrixToSendM[i],blockSize,MPI_DOUBLE,localSubmatrixMNew[i],blockSize,MPI_DOUBLE,0,MPI_COMM_WORLD);
              MPI_Scatter(subMatrixToSendN[i],blockSize,MPI_DOUBLE,localSubmatrixNNew[i],blockSize,MPI_DOUBLE,0,MPI_COMM_WORLD);
            }*/
    
          /*  for(i=0;i<blockSize*blockSize;i++)
            {
                printf("%lf in process ID: %d: \n",localSubmatrixM[i],mypid);
            }*/
        }
        MPI_Barrier(MPI_COMM_WORLD);
        dfinish=MPI_Wtime();
        
   /*     if(mypid==1)
        {
          for(i=0;i<blockSize*blockSize;i++)
          {
            
              printf("subM is %lf ",localSubmatrixN[i]);
            
            printf("\n");
          }
        }*/
       
       //beginning of the fox algorithms, call MPI_BARRIER make sure each process is on the same page
        MPI_Comm_rank(my_row_comm,&myIdInRowGroup);
        MPI_Comm_rank(my_col_comm,&myIdInColGroup);

        //we need to q step to finish the calculation, which q is how many process we have on each row, and also it is how many process we have on each column.
        //now for each of the process, do the regular matrix multiplication
        MPI_Barrier(MPI_COMM_WORLD);
        int transferStep;
         
        
         pstart=MPI_Wtime();
        
        for(transferStep=0;transferStep<q;transferStep++)
        {
          
            //BroadCast M and keep N as what it is. I think for N we don't need a localTempNForIt, it should record all the data by itself
              if(myIdInRowGroup==((mypid/q)+transferStep)%q)
              {
                for(i=0;i<blockSize;i++)
                {
                  //in this way you will still keep the data youw want on each process
                   //localTempMNew[i]=localSubmatrixMNew[i];
                  for(j=0;j<blockSize;j++)
                  {
                    localTempMNew[i][j]=localSubmatrixM[i*blockSize+j];
                  }
                  MPI_Bcast(localTempMNew[i],blockSize,MPI_DOUBLE,myIdInRowGroup,my_row_comm);

                }
         
                
              }
               else
               {
                for(i=0;i<blockSize;i++)
                {
                   for(j=0;j<blockSize;j++)
                  {
                    localTempMNew[i][j]=localSubmatrixM[i*blockSize+j];
                  }
                  MPI_Bcast(localTempMNew[i],blockSize,MPI_DOUBLE,((mypid/q)+transferStep)%q,my_row_comm);

                   //MPI_Bcast(localTempMNew[i],blockSize,MPI_DOUBLE,((mypid/q)+transferStep)%q,my_row_comm);
                }
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
                  if(transferStep==0) //only do this at the first step since need to initialize the localSubMatrixNNew with the localSubmatixN
                  {
                     for(k=0;k<blockSize;k++)
                    { //and k will be used as a tag
                     for(i=0;i<blockSize;i++)
                        {
                        localSubmatrixNNew[k][i]=localSubmatrixN[k*blockSize+i];
                        }
                    }
                   }
                  for(i=0;i<blockSize*blockSize;i++)
                  {
                    
                        for(l=0;l<blockSize;l++)
                        {
                            //this step is very delicate.
                  
                         //subResult[i/blockSize][i%blockSize] =subResult[i/blockSize][i%blockSize]+localTempM[(i/blockSize)*blockSize+l]*localSubmatrixN[l*blockSize+(i%blockSize)];
                          subResult[i/blockSize][i%blockSize]=subResult[i/blockSize][i%blockSize]+localTempMNew[i/blockSize][l]*localSubmatrixNNew[l][i%blockSize];
                         /* printf(" %lf \n",subResult[i/q][i%q]);*/
                        }
                    
                    
                  }
             
            /*    }
              }*/
              

/*
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
        }*/

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
          for(k=0;k<blockSize;k++)
          { //and k will be used as a tag
       
            if(myIdInColGroup!=0)
            {
                //0 here is the tag for send and receive
            //MPI_Send(localSubmatrixN,blockSize*blockSize,MPI_DOUBLE,myIdInColGroup-1,0,my_col_comm);
              MPI_Send(localSubmatrixNNew[k],blockSize,MPI_DOUBLE,myIdInColGroup-1,k,my_col_comm);
             }
             else
            {
             //MPI_Send(localSubmatrixN,blockSize*blockSize,MPI_DOUBLE,q-1,0,my_col_comm);
              MPI_Send(localSubmatrixNNew[k],blockSize,MPI_DOUBLE,q-1,k,my_col_comm);
            }
            //now need to receive
            if(myIdInColGroup!=q-1)
            {
                //MPI_Recv(localSubmatrixN,blockSize*blockSize,MPI_DOUBLE,myIdInColGroup+1,0,my_col_comm,MPI_STATUS_IGNORE);
              MPI_Recv(localSubmatrixNNew[k],blockSize,MPI_DOUBLE,myIdInColGroup+1,k,my_col_comm,MPI_STATUS_IGNORE);
            }
            else
            {
                //MPI_Recv(localSubmatrixN,blockSize*blockSize,MPI_DOUBLE,0,0,my_col_comm,MPI_STATUS_IGNORE);
              MPI_Recv(localSubmatrixNNew[k],blockSize,MPI_DOUBLE,0,k,my_col_comm,MPI_STATUS_IGNORE);
            }
          }
      /*    if(mypid==2&&transferStep==1)
          {
            for(j=0;j<blockSize;j++)
            {
              printf("test: %lf",localSubmatrixNNew[0][j]);
            }
            printf("\n");
          }*/

 
           MPI_Barrier(MPI_COMM_WORLD);
        }
        //ok now, after all the multiplication, we should print out the local result
        MPI_Barrier(MPI_COMM_WORLD);
        pfinish=MPI_Wtime();

        if(mypid==0)
        {
           /* printf("Here is the result: \n");
        for(i=0;i<blockSize;i++)
        {
            for(j=0;j<blockSize;j++)
            {
               printf(" %lf ",subResult[i][j]);
            }
            printf("\n");
        }*/printf("distribution time for parallel multiplication of size %d * %d matrix to %d processes is : %lf seconds\n",rows,cols,mysize,dfinish-dstart);
            printf("calculation time took for parallel multiplication of size %d * %d matrix with %d processes is : %lf seconds\n",rows,cols,mysize,pfinish-pstart);
            printf("total  time of size %d * %d matrix to %d processes is: %lf seconds\n",rows,cols,mysize,dfinish-dstart+pfinish-pstart);

            for(i=0;i<blockSize;i++)
            {
              for(j=0;j<blockSize;j++)
              {
                if(R[i][j]-subResult[i][j]>=0.1)
                {

                  printf("the value not match on row %d, column %d ,%lf \n",i,j,subResult[i][j]);
                }
              }
            }

            printf("if there is no sentence like the value not match printed here, it means our parallel result is correct!! \n");
          
             

        }

        //only test the first block in process 0 and I think it should be good enough to see if we did in a good way.


      
 /*     if(myIdInRowGroup==0)
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

