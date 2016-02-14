#!/bin/bash
mpirun -np 2 ./PI_mpi
mpirun -np 4 ./PI_mpi
mpirun -np 8 ./PI_mpi
mpirun -np 10 ./PI_mpi
mpirun -np 15 ./PI_mpi
mpirun -np 20 ./PI_mpi
mpirun -np 25 ./PI_mpi
mpirun -np 40 ./PI_mpi
