# Makefile — build seq/omp, delegate benchmarking to bench.sh

SHELL := /usr/bin/env bash

# ---- compilers & flags ----
CC        ?= gcc
CSTD      ?= -std=c11
CFLAGS    ?= -O2 -Wall -Wextra $(CSTD)
LDLIBS    ?= -lm

# OpenMP (compile + link)
OMPFLAGS   ?= -fopenmp
OMPLDLIBS  ?= -fopenmp

# ---- sources ----
SRC_SEQ = main.c seq.c
SRC_OMP = main.c omp.c

# ---- quick-run defaults (override on CLI) ----
N  ?= 1000000
SD ?= 2
T  ?= 4

# ---- phony targets ----
.PHONY: all clean veryclean run-seq run-omp benchmark bench

all: seq omp

seq: $(SRC_SEQ)
	$(CC) $(CFLAGS) -DSQ $(SRC_SEQ) -o $@ $(LDLIBS)

omp: $(SRC_OMP)
	$(CC) $(CFLAGS) $(OMPFLAGS) $(SRC_OMP) -o $@ $(LDLIBS) $(OMPLDLIBS)

# quick smoke tests
run-seq: seq
	./seq $(N) $(SD)

#Example
#run the OpenMP build with 100,000,000 samples, seed=2, 8 threads
#make run-omp N=100000000 SD=2 T=8
run-omp: omp
	OMP_NUM_THREADS=$(T) OMP_PLACES=cores OMP_PROC_BIND=close ./omp $(N) $(SD)

# delegate to your script (must be executable)
benchmark: seq omp
	./bench.sh

# alias
bench: benchmark

clean:
	@rm -f seq omp

veryclean: clean
	@rm -f results.csv
