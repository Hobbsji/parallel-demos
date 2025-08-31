#!/bin/bash
### Benchmark script for Monte Carlo OpenMP Assignment ###
### Produces both console tables and a CSV file ###

# Problem sizes (N) and thread counts (T) from assignment
NS=(10000 100000 1000000 10000000 100000000 1000000000)
SD=2
THREADS=(1 2 4 8 16)

# Output CSV file
CSV_FILE="results.csv"
echo "N,Threads,Pi(s),Int(s),Total(s),PiSpd,IntSpd,TotSpd" > $CSV_FILE

# Compile sequential version (define SQ for seq.c)
gcc -O2 -std=c11 -DSQ main.c seq.c -o seq -lm

# Compile OpenMP version
gcc -O2 -fopenmp -std=c11 main.c omp.c -o omp -lm

# Loop over problem sizes
for N in "${NS[@]}"; do
  echo "==============================="
  echo " Problem size N = $N"
  echo "==============================="

  # Sequential (3 runs averaged)
  seq_pi_times=()
  seq_int_times=()
  seq_tot_times=()
  for i in {1..3}; do
    SEQ_OUTPUT=$(./seq $N $SD)
    pi_t=$(echo "$SEQ_OUTPUT"  | grep "Time elapsed" | sed -E 's/.*= ([0-9.]+) .*/\1/' | head -n 1)
    int_t=$(echo "$SEQ_OUTPUT" | grep "Time elapsed" | sed -E 's/.*= ([0-9.]+) .*/\1/' | tail -n 1)
    tot_t=$(awk -v a=$pi_t -v b=$int_t 'BEGIN {print a+b}')
    seq_pi_times+=($pi_t)
    seq_int_times+=($int_t)
    seq_tot_times+=($tot_t)
  done
  SEQ_PI=$(printf "%s\n" "${seq_pi_times[@]}" | awk '{sum+=$1} END {printf "%.6f", sum/NR}')
  SEQ_INT=$(printf "%s\n" "${seq_int_times[@]}" | awk '{sum+=$1} END {printf "%.6f", sum/NR}')
  SEQ_TOT=$(printf "%s\n" "${seq_tot_times[@]}" | awk '{sum+=$1} END {printf "%.6f", sum/NR}')

  echo "Sequential baselines: Pi=$SEQ_PI s, Int=$SEQ_INT s, Total=$SEQ_TOT s"
  echo

  # Header for OpenMP results
  printf "%-8s %-12s %-12s %-12s %-8s %-8s %-8s\n" \
         "Threads" "Pi(s)" "Int(s)" "Total(s)" "PiSpd" "IntSpd" "TotSpd"

  # Loop over thread counts
  for t in "${THREADS[@]}"; do
    export OMP_NUM_THREADS=$t
    export OMP_PLACES=cores
    export OMP_PROC_BIND=close

    pi_times=()
    int_times=()
    tot_times=()

    for i in {1..3}; do
      OMP_OUTPUT=$(./omp $N $SD)
      pi_t=$(echo "$OMP_OUTPUT"  | grep "Time elapsed" | sed -E 's/.*= ([0-9.]+) .*/\1/' | head -n 1)
      int_t=$(echo "$OMP_OUTPUT" | grep "Time elapsed" | sed -E 's/.*= ([0-9.]+) .*/\1/' | tail -n 1)
      tot_t=$(awk -v a=$pi_t -v b=$int_t 'BEGIN {print a+b}')
      pi_times+=($pi_t)
      int_times+=($int_t)
      tot_times+=($tot_t)
    done

    OMP_PI=$(printf "%s\n" "${pi_times[@]}"  | awk '{sum+=$1} END {printf "%.6f", sum/NR}')
    OMP_INT=$(printf "%s\n" "${int_times[@]}" | awk '{sum+=$1} END {printf "%.6f", sum/NR}')
    OMP_TOT=$(printf "%s\n" "${tot_times[@]}" | awk '{sum+=$1} END {printf "%.6f", sum/NR}')

    pi_speed=$(awk -v seq=$SEQ_PI  -v omp=$OMP_PI  'BEGIN {printf "%.2f", seq/omp}')
    int_speed=$(awk -v seq=$SEQ_INT -v omp=$OMP_INT 'BEGIN {printf "%.2f", seq/omp}')
    tot_speed=$(awk -v seq=$SEQ_TOT -v omp=$OMP_TOT 'BEGIN {printf "%.2f", seq/omp}')

    printf "%-8s %-12.6f %-12.6f %-12.6f %-8s %-8s %-8s\n" \
           "$t" "$OMP_PI" "$OMP_INT" "$OMP_TOT" "x$pi_speed" "x$int_speed" "x$tot_speed"

    # Write to CSV
    echo "$N,$t,$OMP_PI,$OMP_INT,$OMP_TOT,$pi_speed,$int_speed,$tot_speed" >> $CSV_FILE
  done

  echo
done

echo "Results saved to $CSV_FILE"
