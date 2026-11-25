# Mission 11: Why Didn't the Attack Work?

## Objective
Inspect the compiler/OS defenses applied to a protected build of `memory_overflow_demo.c` from Mission 10, and connect each to the threat it mitigates.

**Script:** `missions/mission11/run.sh` · **Raw output:** `evidence/mission11/output.txt` (transcribed from `checksec_output.png`, `aslr_value.png` — the team's real VM run).

## Question
Mission 10's overflow ran to completion without crashing on an unprotected build — what changes on a build with the standard hardening flags enabled, and what does each flag actually buy us?

## Prediction
`checksec` should report Full RELRO, a stack canary, NX, and PIE all enabled when compiled with `-fstack-protector-strong -fPIE -pie`, and `/proc/sys/kernel/randomize_va_space` should read `2` (full ASLR) on a modern Ubuntu default.

## Experiment
```bash
gcc -Wall -Wextra -O0 -fstack-protector-strong -fPIE -pie memory_overflow_demo.c -o memory_protected
checksec --file=./memory_protected
cat /proc/sys/kernel/randomize_va_space
readelf -W -l ./memory_protected | grep GNU_STACK
```

## Observation
```
RELRO           STACK CANARY      NX            PIE           RPATH      RUNPATH      Symbols
Full RELRO      Canary found      NX enabled    PIE enabled   No RPATH   No RUNPATH   39 Symbols

$ cat /proc/sys/kernel/randomize_va_space
2
```
All four protections are present on the protected build, confirming the prediction. `randomize_va_space = 2` means Ubuntu is running full ASLR (stack, heap, and shared-library/PIE base addresses all randomized), not just partial (`1`) or disabled (`0`) randomization.

## Think About It

**31. What does ASLR make harder to predict?**
The base addresses of the stack, heap, shared libraries, and (with PIE) the executable's own code — so an attacker who wants to jump to a known address (e.g. a `system()` libc function, or their own injected shellcode) can't rely on it being at the same address run-to-run.

**32. What does NX prevent a writable memory region from being used for?**
NX (no-execute) marks data pages like the stack and heap as non-executable, so even if an attacker successfully injects shellcode bytes into the stack (as in Mission 10's overflow), the CPU refuses to *execute* instructions fetched from that region — the classic "write where you want, but can't execute what you wrote" mitigation.

**33. What does a stack canary attempt to detect?**
A known value placed between local buffers and the saved return address/frame pointer. Before the function returns, the canary is checked; if a buffer overflow (like Mission 10's `memcpy`) overwrote it on the way to the return address, the mismatch is detected and the program aborts (`*** stack smashing detected ***`) instead of returning to a corrupted address.

**34. Why is defense in depth better than relying on one protection?**
Each protection covers a different failure mode: a canary only catches overflows that cross *through* it before reaching the return address (Mission 22's xv6 experiment shows a stack-overflow case a canary wouldn't actually catch); NX stops code injection but not return-oriented programming (reusing existing code); ASLR raises the cost of guessing addresses but can be defeated by an information leak. Stacking all four means an attacker generally has to defeat *several* independent mechanisms simultaneously, not just one.

## Evidence to submit
- [x] `checksec` output (above).
- [x] ASLR value: `2` (full randomization).
- [x] Explanation linking each defense to a threat (above).

## Concept
Defense in depth for memory-safety bugs: compiler-inserted canaries, kernel-enforced NX page permissions, and kernel-randomized address layout, stacked together.

## Defense
Compile with `-fstack-protector-strong -fPIE -pie` (and keep `randomize_va_space=2`) as a baseline for any C/C++ project, rather than relying on bug-free code alone.

## Verification
`checksec` itself is the verification tool here — it reads the binary's ELF headers/dynamic section to confirm each mitigation is actually compiled in, rather than trusting the build flags were applied correctly.

## Reflection
Without these, Mission 10's silent overflow becomes a much more dangerous primitive: predictable addresses (no ASLR) + executable stack (no NX) + no canary is close to the classic "smash the stack for fun and profit" scenario from the 1990s, which is exactly why modern distributions enable all of these by default.
