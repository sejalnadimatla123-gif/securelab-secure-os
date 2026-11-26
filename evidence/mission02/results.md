# Mission 2: Meet the Kernel

## Objective
Observe the boundary between an application and the operating system by tracing the system calls a tiny program makes.

**Source:** `missions/mission02/syscall_demo.c` · **Script:** `missions/mission02/run.sh` · **Raw output:** `evidence/mission02/output.txt`

## Question
Which system calls does a program that creates and writes a file actually issue, and who services them?

## Prediction
The program should issue at least `openat`/`open`, `write`, and `close`, each of which traps into the kernel; the C library functions are thin wrappers, not the real implementation.

## Experiment
```bash
gcc -Wall -Wextra syscall_demo.c -o syscall_demo
./syscall_demo
strace ./syscall_demo 2>&1 | head -50
```

## Observation (real strace on the Ubuntu lab machine)
```
$ ./syscall_demo
$ cat hello.txt
Hello from user space!
```
The program behaves as written: `hello.txt` is created and contains the expected message. The real `strace ./syscall_demo` trace (full trace in `evidence/mission02/output.txt`) confirms the predicted sequence, after the dynamic linker's own setup syscalls (`mmap`/`openat` on `ld.so.cache` and `libc.so.6`, `mprotect`, etc.):
```
openat(AT_FDCWD, "hello.txt", O_WRONLY|O_CREAT|O_TRUNC, 0644) = 3
write(3, "Hello from user space!\n", 23) = 23
close(3)                                = 0
exit_group(0)                           = ?
```

## Think About It

**4. Which system calls did you observe?**
`open`/`openat` (create the file), `write` (copy the message into the kernel's page cache for that file), and `close` (release the file descriptor). Modern glibc on Linux actually emits `openat` even when the source calls `open()`, since `open()` is implemented as a thin wrapper around `openat(AT_FDCWD, …)`.

**5. Why should an application not directly control hardware?**
Hardware (disks, NICs) is a shared resource; if any process could issue raw I/O instructions, one buggy or malicious program could corrupt another process's data, read arbitrary disk blocks, or hang the device for everyone. The kernel centralizes hardware access so it can enforce permissions, scheduling fairness, and a consistent file-system abstraction (that's exactly what `open`/`write`/`close` are proxies for).

**6. Why is the kernel part of the trusted computing base?**
The TCB is everything that must be correct for the system's security guarantees to hold. Every access-control decision in this project (`chmod`, ACLs, capabilities, AppArmor) is ultimately enforced *inside the kernel* when a system call is made. If the kernel itself is compromised or buggy, no higher-level check can be trusted, so it must sit inside the TCB boundary by definition.

## Evidence to submit
- [x] A short trace with open/write/close identified (above, real `strace` output from the Ubuntu lab machine).
- [x] Application → system call → kernel → resource diagram:

```
 user space                         kernel space
┌────────────────┐   open()    ┌───────────────────────┐
│ syscall_demo    │ ──────────▶│ syscall dispatch table │
│  (user process) │   write()  │  → VFS → filesystem    │──▶ disk / page cache
│                 │ ◀────────── │    driver              │
└────────────────┘   close()   └───────────────────────┘
        ▲ trap/return (mode switch: ring 3 ⇄ ring 0) ▲
```

## Concept
System calls are the *only* sanctioned doorway from user space into kernel space; each one causes a mode switch where the CPU starts trusting kernel code instead of the calling process.

## Defense
Syscall mediation itself is the defense: every `open`/`write` is checked against the calling process's credentials (Mission 1) before the kernel performs the operation.

## Verification
The program's actual behavior (file created, correct contents) matches the predicted syscall sequence; the real `strace` run confirmed the exact syscalls and their arguments.

## Reflection
Without kernel mediation of system calls, "security" would just be an honor system between user-space processes — any DAC/ACL/capability check from later missions could be bypassed by a process that talks to hardware directly.
