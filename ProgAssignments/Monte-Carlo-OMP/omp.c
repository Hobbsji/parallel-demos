#include <stdlib.h>
#include <omp.h>
#include <stdio.h>

#include "util.h"

double monte_carlo_pi_omp(long long N, unsigned int seed) {
    long long hits = 0;

    #pragma omp parallel reduction(+:hits)
    {
        rng32_t rand;
        int tid = omp_get_thread_num();
        rand.s = mix_seed(seed,tid);  // Seed

        #pragma omp for
        for (long long i = 0; i < N; i++) {
            double x = (double)xorshift32(&rand) / UINT32_MAX;
            double y = (double)xorshift32(&rand) / UINT32_MAX;

            if (x * x + y * y <= 1.0) {
                hits++;
            }
        }
    }

    //printf("Final Hits: %lld\n", hits);
    double estimated_pi = 4.0 * (double)hits / (double)N;
    return estimated_pi;
}

double monte_carlo_integral_omp(long long N, unsigned int seed) {
    /* TODO: Put your OpenMP code of monte_carlo_integral here. 
    Note: You need to generate seed per thread, you can call "mix_seed" function defined in "util.h" file. */
    double sum = 0.0;
    #pragma parallel reduction(+:sum)
    {
        int tid = omp_get_thread_num();
        rng32_t rng = {.s = mix_seed(seed, tid)};

        #pragma omp for
        for(long long i=0; i<N; ++i) {
            double x = uniform_01(&rng);
            double y = f(x);
            sum  += y;
        }
    }

    double I_hat = sum / (double)N;
    return I_hat;
}