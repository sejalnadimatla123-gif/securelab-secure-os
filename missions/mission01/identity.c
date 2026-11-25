/* Mission 1: Who Are You? — compare shell identity with process identity. */
#include <stdio.h>
#include <unistd.h>

int main(void) {
    printf("Real UID      : %d\n", (int)getuid());
    printf("Effective UID : %d\n", (int)geteuid());
    printf("Real GID      : %d\n", (int)getgid());
    printf("Effective GID : %d\n", (int)getegid());
    return 0;
}

/* Compile:
 *   gcc identity.c -o identity
 * Run:
 *   ./identity
 */
