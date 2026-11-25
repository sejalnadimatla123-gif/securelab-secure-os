/* Mission 4: Can One Process Read Another? — print this process's PID and a
 * stack address, then hold still so a second terminal can inspect
 * /proc/<PID>/maps. */
#include <stdio.h>
#include <unistd.h>

int main(void) {
    int secret = 12345;

    printf("PID     = %d\n", (int)getpid());
    printf("&secret = %p\n", (void *)&secret);
    printf("secret  = %d\n", secret);
    printf("Inspect /proc/%d/maps for 30 seconds.\n", (int)getpid());

    sleep(30);
    return 0;
}

/* Compile:
 *   gcc -Wall -Wextra address_space.c -o address_space
 * Run:
 *   ./address_space
 * In another terminal:
 *   cat /proc/<PID>/maps
 */
