#!/bin/bash
### Note: This script provides the commands you need. You may need to adjust paths/sizes. ###

# Problem size
N=100000000   # number of samples

# Compile sequential version
# gcc -O2 -std=c11 main.c seq.c -o seq -lm

# Compile OpenMP version
gcc -O2 -fopenmp -std=c11 main.c omp.c -o omp -lm

# Run sequential
# echo "===== Running Sequential Version ====="
# ./seq $N

# Run OpenMP with different thread counts, multiple trials
echo "===== Running OpenMP Version ====="
for t in 1 2 4 6 12; do
  echo "---- OMP_NUM_THREADS=$t ----"
  export OMP_NUM_THREADS=$t
  # pin to cores for consistency
  export OMP_PLACES=cores
  export OMP_PROC_BIND=close

  # Run multiple times to see variability
  for i in {1..3}; do
    ./omp $N
  done
done
