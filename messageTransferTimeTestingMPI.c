#include "mpi.h"
#include <stdio.h>
#include <sys/time.h>
#include <time.h>
#include <stdlib.h>

#define REPS 30 //this means every experiment will repeat 30 times
#define MAXLENGTH 1100000 //a little big bigger than our largest one

int main(int argc, char* argv[])
{
	int i,n, length;
	int *inmsg,*outmsg;
	int mypid,mysize;
	int rc;
	int sint;
	double start, finish,time;
	double bw;
	MPI_Status status;

	sint=sizeof(int);

	rc=MPI_Init(&argc,&argv);
	rc|=MPI_Comm_size(MPI_COMM_WORLD,&mysize);
	rc|=MPI_Comm_rank(MPI_COMM_WORLD,&mypid);

	if(mysize!=2)
	{
		fprintf(stderr,"now we only test message passing time between 2 processes\n");
		exit(1);
	}

	length=1;

	inmsg=(int *) malloc(MAXLENGTH*sizeof(int));
	outmsg=(int *) malloc(MAXLENGTH*sizeof(int));

	//synchronize the process, so the MPI_Barrier will return only if all the processes all called it
    
    rc=MPI_Barrier(MPI_COMM_WORLD);

    if(mypid==0)
    {
        for(i=1;i<=4;i++)
        {
        	time=0.00000000000000;
        	printf("\n\nDoing time test for:\n");
        	printf("Message length=%d int value\n",length);
        	printf("Message size =%d Bytes\n",sint*length);
        	printf("Number of Reps=%d\n",REPS);

        	start=MPI_Wtime();
        	for(n=1;n<=REPS;n++)
        	{
        		rc=MPI_Send(&outmsg[0],length,MPI_INT,1,0,MPI_COMM_WORLD);
        		rc= MPI_Recv(&inmsg[0],length,MPI_INT,1,0,MPI_COMM_WORLD,&status);

        	}
        	finish=MPI_Wtime();

        	//calculate the average time and bandwidth

        	time=finish-start;
        	printf("***delivering message avg= %f Sec for lengthSize=%d\n",time/REPS,length);
            bw=2.0*REPS*sint*length/time;

            printf("*** bandwidth=%f Byte/Sec\n",bw);

            //increase the length 
            length=100*length;
        }    
    }
    //task 1 processing now
    if(mypid==1)
    {
      for(i=1;i<=4;i++)
      {
      	for(n=1;n<=REPS;n++)
      	{
      		rc=MPI_Recv(&inmsg[0],length,MPI_INT,0,0,MPI_COMM_WORLD,&status);
      		rc = MPI_Send(&outmsg[0],length,MPI_INT,0,0,MPI_COMM_WORLD);

      	}
      	length=100*length;
      }
    }


  MPI_Finalize();
  exit(0);
}
