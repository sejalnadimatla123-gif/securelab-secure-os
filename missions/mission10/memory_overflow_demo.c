/* Mission 10: The Dangerous Array — INTENTIONALLY UNSAFE FOR THE LAB.
 * Observation only. Do not develop shellcode/payloads against this. */
#include <stdio.h>
#include <string.h>

int main(void) {
    char buffer[16];
    const char input[] = "THIS_INPUT_IS_LONGER_THAN_SIXTEEN";

    printf("Copying %zu bytes into a 16-byte buffer...\n",
           strlen(input) + 1);

    memcpy(buffer, input, strlen(input) + 1);

    printf("Program reached the end of the copy.\n");
    return 0;
}

/* Compile:
 *   gcc -Wall -Wextra -O0 -g memory_overflow_demo.c -o memory_overflow_demo
 * Run:
 *   ./memory_overflow_demo
 */
