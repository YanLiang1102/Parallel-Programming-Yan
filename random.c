#include "mpi.h"
#include <stdio.h>
#include <sys/time.h>
#include <time.h>
#include <stdlib.h>
#include <stdbool.h>
        #define MAXLENGTH 20000001 //basically I want each process to generate 100000 points so make the maximum length a little bit bigger here
        #define NUMPOINTS 20000000 //this is 20 million is the total point generating each process will get NUMPOINTS/processNumber
       
        void generateRandomNumbers(int num_size,double *localDataX,double *localDataY,int *localCount);
        bool determinePointWithInCircle(double x, double y);
        double r2();
        
       
        int main(int argc, char* argv[]) {
         
          double *localDataX,*localDataY,*totalData;
          int localCount=0;
          int totalCount;
          int mypid,mysize;
          double start, finish,timeTook;
          int numberPointsInEachProcess;
          localDataX=(double *) malloc(MAXLENGTH*sizeof(double));
          localDataY=(double *) malloc(MAXLENGTH*sizeof(double));
          //generateRandomNumbers(10,localDataX,localDataY);
          MPI_Init(&argc,&argv);
          MPI_Comm_size(MPI_COMM_WORLD,&mysize);
          MPI_Comm_rank(MPI_COMM_WORLD,&mypid);

           MPI_Barrier(MPI_COMM_WORLD);//this is to synchronize all the processes
           start= MPI_Wtime();
          if(mypid==0)
          { 
            numberPointsInEachProcess=NUMPOINTS/mysize;
            //seems like without adding mypid it is two fast for the current time to distinguish the seeds are different
            srand(time(NULL)+100);//can't put this inside of the loop or inside of the function,
            generateRandomNumbers(numberPointsInEachProcess,localDataX,localDataY,&localCount);
            MPI_Reduce(&localCount,&totalCount,1,MPI_INT,MPI_SUM,0,MPI_COMM_WORLD);
            printf("localCount %d with processId: %d \n",localCount,mypid);
            printf("totalCount: %d \n",totalCount);
            printf("the estimate of pi using %d points: %f \n",numberPointsInEachProcess*mysize,totalCount*1.0/(mysize*numberPointsInEachProcess)*1.0*4);
           
          }
          if(mypid!=0)
          {
            numberPointsInEachProcess=NUMPOINTS/mysize;
            srand(time(NULL)+mypid);///can't put this inside of the loop or inside of the function,
            generateRandomNumbers(numberPointsInEachProcess,localDataX,localDataY,&localCount);
            printf("localCount %d with processId: %d \n",localCount,mypid);
            MPI_Reduce(&localCount,&totalCount,1,MPI_INT,MPI_SUM,0,MPI_COMM_WORLD);

          }
          //synchronize again here
          MPI_Barrier(MPI_COMM_WORLD);
          finish=MPI_Wtime();
          //just print in the first process will be fine
          if(mypid==0)
            {
            timeTook=finish-start;
            printf("***time consumed with %d processes is %lf seconds\n",mysize,timeTook);
            printf("\n\n");
            }
   
          free(localDataX);
          free(localDataY);
          MPI_Finalize();
          exit(0);
        }

        void generateRandomNumbers(int num_size,double *localDataX, double *localDataY, int *localCount)
        {  
            int n;
            
            
            //generate x coordinate
            for(n=0;n<=num_size-1;n++)
            {   

               // localDataX[n]=random_number(0,10)/10.0+random_number(0,10)/100.0+random_number(0,10)/1000.0; //generate random number with in 0 to 1
             //localDataX[n]=random_number(0,1);
                localDataX[n]=r2();
                
                //printf("loop %d x:%f y:%f %d \n",n,localDataX[n],localDataY[n],determinePointWithInCircle(localDataX[n],localDataY[n]));
                
            }
            //using another seed and generate y coordinate
               srand(time(NULL));
            for(n=0;n<=num_size-1;n++)
            {
              //localDataY[n]=random_number(0,10)/10.0+random_number(0,10)/100.0+random_number(0,10)/1000.0;
               // localDataY[n]=random_number(0,1);
                 localDataY[n]=r2();
            }
            //and leave the test here, by doing this will make sure x and y not generated the same array
            for(n=0;n<=num_size-1;n++)
            {
                if(determinePointWithInCircle(localDataX[n],localDataY[n]))
                    (*localCount)++;
            }
            

        }
        //will return true if the point is within the circle
        bool determinePointWithInCircle(double x, double y)
        {
            if(x*x+y*y<=1)
                return true;
            else
                return false;
        }
        //this is the way to generate random number between 0 and 1
        double r2()
        {
            return (double)rand() / (double)RAND_MAX ;
        }