//mpicc mpiscan.c -o mpi -lm
//mpiexec -n 16 ./mpi>>result
#include "mpi.h"
#include <math.h>
#include <stdlib.h>
#define WCOMM MPI_COMM_WORLD
#define NUMPCS 16
#define COUNTSIZE 32
main(int argc, char **argv){
  int mype, ierr;
  ierr = MPI_Init(&argc, &argv);
  ierr = MPI_Comm_rank(WCOMM, &mype);
  int localArray[COUNTSIZE];
  int localPrefix[COUNTSIZE+1]; //this is to store the locally calculated prefix.
  localPrefix[0]=0;
  int myLocal=0;
  int totalLocal=0;
  int i;
  int j;

  srand(time(NULL)+mype);
  

  for(i = 0; i < NUMPCS; i++)
  {
    if (i == mype)
    {
    for(j=0;j<COUNTSIZE;j++)
    {
      //only generate int within range 0 and 9.
      localArray[j]=rand()%10;
      //printf("from process: %d arrayindex: %d arrayvalue: %d \n",mype,j,localArray[j]);
      localPrefix[j+1]=localPrefix[j]+localArray[j];
      printf("from process: %d local_prefix %d accumulate_value %d \n",mype,j,localPrefix[j+1]);
    }
    myLocal=localPrefix[COUNTSIZE];
          printf("from process: %d local_total_prefix %d \n",mype,myLocal);
    totalLocal=myLocal;
    }
  }

    ierr = MPI_Scan( \
    &myLocal, &totalLocal,1, MPI_INT, MPI_SUM, WCOMM);

  for (i = 0; i < NUMPCS; i++)
  {
    if (i == mype)
    {
       printf("process %d: global_prefix_sum = %d \n",mype,totalLocal-myLocal);
       printf("following are process local value plus previous prefix value: \n");
       for(j=1;j<=COUNTSIZE;j++)
       {
        printf("process %d, local_step: %d, local+prefix_value: %d \n",mype,j,localPrefix[j]+totalLocal-myLocal);
       }

    }
  }
 ierr = MPI_Finalize();
}
