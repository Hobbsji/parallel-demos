#!/bin/bash
THREADS="$1"

export OMP_NUM_THREADS=$THREADS   # sets number of OpenMP threads
export OMP_PLACES=cores
export OMP_PROC_BIND=close

gcc -O2 -fopenmp -std=c11 main.c omp.c -o omp -lm

echo "Running with $OMP_NUM_THREADS threads..."
./omp 500000000 2

rm omp


