
#include <stdio.h>
#include <string.h>
#include <unistd.h>
#include <sys/wait.h>

int main(void) {
    int fd[2];

    if (pipe(fd) == -1) {
        perror("pipe");
        return 1;
    }

    pid_t pid = fork();

    if (pid == -1) {
        perror("fork");
        return 1;
    }

    if (pid == 0) {
        // Child process: read from pipe
        close(fd[1]);

        char buffer[128] = {0};
        ssize_t n = read(fd[0], buffer, sizeof(buffer) - 1);

        if (n >= 0)
            printf("Child received: %s\n", buffer);

        close(fd[0]);
        return 0;
    }

    // Parent process: write to pipe
    close(fd[0]);

    const char msg[] = "Hello from the parent";

    if (write(fd[1], msg, strlen(msg) + 1) == -1)
        perror("write");

    close(fd[1]);

    waitpid(pid, NULL, 0);

    return 0;
}
