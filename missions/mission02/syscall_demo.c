/* Mission 2: Meet the Kernel — a user-space program crossing into the kernel
 * via system calls (open/write/close). */
#include <fcntl.h>
#include <stdio.h>
#include <unistd.h>

int main(void) {
    int fd = open("hello.txt", O_CREAT | O_WRONLY | O_TRUNC, 0644);
    if (fd == -1) {
        perror("open");
        return 1;
    }

    const char msg[] = "Hello from user space!\n";
    ssize_t n = write(fd, msg, sizeof(msg) - 1);
    if (n < 0) {
        perror("write");
        close(fd);
        return 1;
    }

    close(fd);
    return 0;
}

/* Compile:
 *   gcc syscall_demo.c -o syscall_demo
 * Trace (Linux VM):
 *   strace ./syscall_demo 2>&1 | head -50
 */
