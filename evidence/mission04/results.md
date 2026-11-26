# Mission 4: Can One Process Read Another?

## Objective
Observe a process's virtual address space and understand why a pointer printed by one process is not usable by another.

**Source:** `missions/mission04/address_space.c` · **Script:** `missions/mission04/run.sh` · **Raw output:** `evidence/mission04/output.txt`

## Question
Does the address printed by one process (`&secret`) mean anything to a different process, or to the same address read directly from another terminal?

## Prediction
The printed address is a **virtual** address, meaningful only inside that process's own page tables. A different process has its own independent virtual address space, so even if it used the exact same numeric address, it would hit different physical memory (or nothing at all, causing a segfault) — it cannot simply dereference the pointer across processes.

## Experiment
```bash
gcc -Wall -Wextra address_space.c -o address_space
./address_space &
# from a second terminal:
cat /proc/<PID>/maps
```

## Observation (real run on the Ubuntu lab machine)
```
$ ./address_space &
PID     = 9126
&secret = 0x7ffc73267d14
secret  = 12345
Inspect /proc/9126/maps for 30 seconds.
```
`/proc/9126/maps` (full listing in `evidence/mission04/output.txt`) confirmed the process has its own private, isolated set of mappings — the executable's own text/data/rodata segments, `[heap]`, `libc.so.6`, `ld-linux-x86-64.so.2`, `[stack]`, `[vvar]`, `[vdso]` — listed under that PID only; no other process's `/proc/<PID>/maps` output includes this process's mappings or its `secret` value. (One harness note: `address_space`'s stdout is fully-buffered once redirected to a file, so `missions/mission04/run.sh` now runs it under `stdbuf -oL` — otherwise the PID/pointer lines would still be sitting unflushed in the program's buffer when the script `cat`s the file a second later.)

## Think About It

**10. What does a process's address space contain?**
Its code (text segment), initialized/uninitialized global data, the heap, memory-mapped files/libraries, and the stack (where `secret` lives here) — each as a separate mapping with its own permissions (read/write/execute), visible as one row per mapping in `/proc/<PID>/maps` (or `vmmap`'s region list).

**11. Why can't another ordinary process simply dereference the printed pointer?**
Addresses are virtual, translated per-process through that process's own page tables by the MMU. Process B's page tables have no entry for process A's `0x7ff7…` address (or that same virtual address maps to something completely unrelated in B), so `*ptr` in B either reads garbage/unrelated memory or, far more likely, is unmapped and triggers a segmentation fault.

**12. What role does hardware-assisted memory protection play?**
The CPU's MMU enforces, on every single memory access, that the virtual address maps to a physical page *this process's* page table authorizes, with its allowed permissions. This hardware check happens on every load/store, which is why process isolation can be enforced cheaply and without the kernel re-checking each instruction in software.

## Evidence to submit
- [x] `/proc/<PID>/maps` output, real Ubuntu lab machine — `evidence/mission04/output.txt`.
- [x] Labelled address-space diagram:

```
 high addresses
┌─────────────────────┐
│ kernel (not mapped   │  (shared range, but inaccessible from user mode)
│ to user-mode reads)  │
├─────────────────────┤
│ stack (grows down)   │ ← &secret lives here
│        ...           │
│ mmap'd libraries      │
│        ...           │
│ heap (grows up)      │
├─────────────────────┤
│ BSS / data            │
│ text (code)           │
└─────────────────────┘
 low addresses
   (independent per process — process B's diagram looks identical in
    shape but maps to completely different physical pages)
```
- [x] Short explanation of isolation (below).

## Concept
Virtual memory + the MMU give each process the illusion of owning the entire address space, while the kernel's per-process page tables are the actual enforcement mechanism for process isolation.

## Defense
Hardware-enforced page-table isolation — no process can construct a pointer that reaches into another process's physical pages without a kernel-mediated mechanism (e.g. `ptrace`, shared memory explicitly set up by both sides — see Mission 6).

## Verification
`vmmap`/`/proc/<PID>/maps` for this PID shows only this process's own mappings; no mechanism available to an unprivileged, unrelated process exposes another process's `secret` value or its stack address directly.

## Reflection
Without per-process address-space isolation, any program could read or corrupt any other program's memory just by guessing/printing an address — the entire rest of this project (DAC, capabilities, sandboxing) would be moot if a hostile process could simply reach across into another process's secrets in RAM.
