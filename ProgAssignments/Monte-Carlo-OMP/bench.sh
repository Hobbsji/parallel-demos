#!/usr/bin/env bash
# Benchmark: seq row as "1*", CSV minimal columns, plus console table per N
set -euo pipefail

# ---- Config ----
NS=(10000 100000 1000000 10000000 100000000 1000000000)
THREADS=(1 2 4 8 16)   # OMP threads; seq is its own "1*" row
SEED=2
RUNS=2

SEQ=./seq
OMP=./omp

OUTCSV=results.csv

# ---- Helpers ----
mean_f() { awk '{s+=$1} END{if(NR>0) printf "%.6f", s/NR; else print "0"}'; }  # times
mean_g() { awk '{s+=$1} END{if(NR>0) printf "%.6g", s/NR; else print "0"}'; }  # errors (keep sci)

# Scoped extractors (use Task markers printed by your programs)
pi_err_of() { awk '
  /^===== Task 1:/ {in1=1; in2=0; next}
  /^===== Task 2:/ {in1=0; in2=1; next}
  in1 && /Absolute error/ {
    if (match($0, /[-+]?[0-9]*\.?[0-9]+([eE][-+]?[0-9]+)?/)) { print substr($0,RSTART,RLENGTH); exit }
  }' <<<"$1"; }

int_err_of() { awk '
  /^===== Task 1:/ {in1=1; in2=0; next}
  /^===== Task 2:/ {in1=0; in2=1; next}
  in2 && /Absolute error/ {
    if (match($0, /[-+]?[0-9]*\.?[0-9]+([eE][-+]?[0-9]+)?/)) { print substr($0,RSTART,RLENGTH); exit }
  }' <<<"$1"; }

pi_time_of() { awk '
  /^===== Task 1:/ {in1=1; in2=0; next}
  /^===== Task 2:/ {in1=0; in2=1; next}
  in1 && /Time elapsed/ {
    if (match($0, /[-+]?[0-9]*\.?[0-9]+([eE][-+]?[0-9]+)?/)) { print substr($0,RSTART,RLENGTH); exit }
  }' <<<"$1"; }

int_time_of() { awk '
  /^===== Task 1:/ {in1=1; in2=0; next}
  /^===== Task 2:/ {in1=0; in2=1; next}
  in2 && /Time elapsed/ {
    if (match($0, /[-+]?[0-9]*\.?[0-9]+([eE][-+]?[0-9]+)?/)) { print substr($0,RSTART,RLENGTH); exit }
  }' <<<"$1"; }

# ---- Build ----
gcc -O2 -std=c11 -DSQ main.c seq.c -o seq -lm
gcc -O2 -fopenmp -std=c11 main.c omp.c -o omp -lm

# ---- CSV header ----
echo "N,Threads,PiErrMean,PiTime(s),PiSpdUp,IntErrMean,IntTime(s),IntSpdUp" > "$OUTCSV"

# ---- Main loop ----
for N in "${NS[@]}"; do
  echo
  echo "=== N=$N ==="
  printf "%-6s %-10s %-10s %-8s %-12s %-12s %-8s\n" \
         "Thr" "PiErr" "PiTime" "PiSpd" "IntErr" "IntTime" "IntSpd"

  # ----- Sequential baseline (RUNS averaged) -----
  seq_pi_errs=(); seq_pi_ts=()
  seq_int_errs=(); seq_int_ts=()

  for r in $(seq 1 "$RUNS"); do
    OUT="$($SEQ "$N" "$SEED")"
    seq_pi_errs+=("$(pi_err_of  "$OUT")")
    seq_pi_ts+=("$(pi_time_of "$OUT")")
    seq_int_errs+=("$(int_err_of "$OUT")")
    seq_int_ts+=("$(int_time_of "$OUT")")
  done

  SEQ_PI_ERR=$( printf "%s\n" "${seq_pi_errs[@]}" | mean_g )
  SEQ_PI_TIME=$(printf "%s\n" "${seq_pi_ts[@]}"   | mean_f )
  SEQ_INT_ERR=$( printf "%s\n" "${seq_int_errs[@]}"| mean_g )
  SEQ_INT_TIME=$(printf "%s\n" "${seq_int_ts[@]}"  | mean_f )

  # Console row for seq (Threads = 1*)
  printf "%-6s %-10s %-10.6f %-8s %-12s %-12.6f %-8s\n" \
         "1*" "$SEQ_PI_ERR" "$SEQ_PI_TIME" "1.00" "$SEQ_INT_ERR" "$SEQ_INT_TIME" "1.00"

  # CSV row for seq
  echo "$N,1*,$SEQ_PI_ERR,$SEQ_PI_TIME,1.00,$SEQ_INT_ERR,$SEQ_INT_TIME,1.00" >> "$OUTCSV"

  # ----- OpenMP runs for each t -----
  for t in "${THREADS[@]}"; do
    export OMP_NUM_THREADS="$t"
    export OMP_PLACES=cores
    export OMP_PROC_BIND=close

    omp_pi_errs=(); omp_pi_ts=()
    omp_int_errs=(); omp_int_ts=()

    for r in $(seq 1 "$RUNS"); do
      OUT="$($OMP "$N" "$SEED")"
      omp_pi_errs+=("$(pi_err_of  "$OUT")")
      omp_pi_ts+=("$(pi_time_of "$OUT")")
      omp_int_errs+=("$(int_err_of "$OUT")")
      omp_int_ts+=("$(int_time_of "$OUT")")
    done

    OMP_PI_ERR=$( printf "%s\n" "${omp_pi_errs[@]}" | mean_g )
    OMP_PI_TIME=$(printf "%s\n" "${omp_pi_ts[@]}"   | mean_f )
    OMP_INT_ERR=$( printf "%s\n" "${omp_int_errs[@]}"| mean_g )
    OMP_INT_TIME=$(printf "%s\n" "${omp_int_ts[@]}"  | mean_f )

    # Speedups vs sequential means
    pi_spd=$(  awk -v s="$SEQ_PI_TIME"  -v o="$OMP_PI_TIME"  'BEGIN{printf "%.2f", s/o}' )
    int_spd=$( awk -v s="$SEQ_INT_TIME" -v o="$OMP_INT_TIME" 'BEGIN{printf "%.2f", s/o}' )

    # Console row for OMP
    printf "%-6s %-10s %-10.6f %-8s %-12s %-12.6f %-8s\n" \
           "$t" "$OMP_PI_ERR" "$OMP_PI_TIME" "$pi_spd" "$OMP_INT_ERR" "$OMP_INT_TIME" "$int_spd"

    # CSV row
    echo "$N,$t,$OMP_PI_ERR,$OMP_PI_TIME,$pi_spd,$OMP_INT_ERR,$OMP_INT_TIME,$int_spd" >> "$OUTCSV"
  done
done

echo
echo "Wrote $OUTCSV"
