
#include <pthread.h>
#include <stdio.h>

long counter = 0;
pthread_mutex_t lock = PTHREAD_MUTEX_INITIALIZER;

void *worker(void *arg) {
    (void)arg;

    for (long i = 0; i < 1000000; i++) {
        /*
         * TODO:
         * 1. Run once with NO mutex around this increment.
         * 2. Then add pthread_mutex_lock(&lock).
         * 3. Increment.
         * 4. Add pthread_mutex_unlock(&lock).
         */

        counter++;
    }

    return NULL;
}

int main(void) {
    pthread_t t1, t2;

    pthread_create(&t1, NULL, worker, NULL);
    pthread_create(&t2, NULL, worker, NULL);

    pthread_join(t1, NULL);
    pthread_join(t2, NULL);

    printf("Expected: 2000000\n");
    printf("Actual : %ld\n", counter);

    pthread_mutex_destroy(&lock);

    return 0;
}

/* Compile:
   gcc -Wall -Wextra -O0 -pthread race_demo.c -o race_demo
*/
