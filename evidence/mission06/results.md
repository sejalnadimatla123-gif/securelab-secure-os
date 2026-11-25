
# Mission 6: Inter-Process Communication

## Objective
Understand IPC using pipes and compare pipes with shared memory.

## Experiment: Pipe-Based IPC

### Implementation
- Created a pipe using pipe().
- Created a child process using fork().
- Parent process wrote a message using write().
- Child process received the message using read().
- Closed unused file descriptors in both processes.
- Used waitpid() to wait for child process completion.

### Output
Child received: Hello from the parent

## Pipes vs Shared Memory

| Feature | Pipes | Shared Memory |
|---|---|---|
| Communication | Data transfer | Common memory region |
| Speed | Generally slower | Generally faster |
| Synchronization | Basic pipe operations managed by OS | Requires explicit coordination |
| Complexity | Simple | More complex |

## Security Properties of IPC

Potential security risks:
- Unauthorized access to communication endpoints.
- Data tampering.
- Information leakage.
- Process impersonation.

## Proposed Security Controls
- Restrict endpoint access using permissions.
- Authenticate communicating processes.
- Validate incoming messages.
- Encrypt sensitive information where necessary.
- Apply least-privilege principles.

## Observation
The parent process successfully transmitted a message to the child process through a pipe.

**Source:** `missions/mission06/pipe_ipc.c` · **Script:** `missions/mission06/run.sh` · **Raw output:** `evidence/mission06/output.txt`

## Think About It

**16. Why is a pipe different from shared memory?**
A pipe is a kernel-mediated byte stream: every `write()` and `read()` is a system call, so the kernel copies data between the two processes and enforces ordering — one process can't see the other's writes until the kernel delivers them. Shared memory instead maps the *same physical pages* into both processes' address spaces, so either side can read or write instantly with no kernel involvement on the data path, but also with no built-in ordering or notification.

**17. Why does shared memory normally require synchronization?**
Because there is no kernel mediation of individual accesses, nothing stops both processes from reading/writing the same memory at the same time — exactly the race-condition problem from Mission 5, but between processes instead of threads. A mutex/semaphore (often itself placed in a small shared-memory region) is needed to coordinate who may read or write when.

**18. What must be protected in secure IPC: the data, the endpoint, or both?**
Both. Protecting only the data (e.g. encrypting the message) doesn't stop an unauthorized process from attaching to the shared-memory segment or reading from the pipe's file descriptor if it somehow obtains it; protecting only the endpoint (restrictive permissions on who may open/attach) doesn't stop a legitimate-but-compromised peer from tampering with the data once connected. A secure design needs permission control on *who can reach the endpoint* and validation/integrity checks on *what travels through it*.

## Conclusion
Pipes provide a straightforward method of communication between processes. Shared memory can provide faster communication but requires careful synchronization and access control.
