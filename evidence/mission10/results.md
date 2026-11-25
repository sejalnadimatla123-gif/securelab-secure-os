# Mission 10: The Dangerous Array

## Objective
Understand how an unchecked `memcpy` can corrupt memory, observed safely inside the VM (no exploit payloads).

**Source:** `missions/mission10/memory_overflow_demo.c` · **Script:** `missions/mission10/run.sh` · **Raw output:** `evidence/mission10/output.txt` (transcribed from `compiler_run_output.png`, the team's real VM run).

## Question
What happens when a program copies more bytes into a stack buffer than the buffer can hold?

## Prediction
`strlen(input) + 1` is 35 bytes (or `strlen(input)` = 34, depending on the exact call) going into a 16-byte `buffer`. GCC should warn about the overflow at compile time (`-Wstringop-overflow`), and at runtime the program may still "appear" to finish normally if the overwritten stack bytes don't happen to corrupt anything the program checks before returning — undefined behavior doesn't guarantee a visible crash.

## Experiment
```bash
gcc -Wall -Wextra -O0 -g memory_overflow_demo.c -o memory_overflow_demo
./memory_overflow_demo
```

## Observation
```
$ gcc -Wall -Wextra -O0 -g memory_overflow_demo.c -o memory_overflow_demo
memory_overflow_demo.c:11:9: warning: 'memcpy' writing 33 bytes into a
region of size 16 overflows the destination [-Wstringop-overflow=]

$ ./memory_overflow_demo
Copying 33 bytes into a 16-byte buffer...
Finished copying data
```
The compiler caught the overflow statically and warned about it, but the program still ran to completion without crashing — it did not display any unexpected errors and terminated as expected. This confirms the prediction: GCC's static analysis flags the bug, but the unsafe `memcpy` itself still executes; whatever stack memory the extra 17 bytes (33 − 16) landed on did not happen to be something the program checked before `return 0`, so the corruption was silent rather than visibly fatal.

## Buffer boundary vs copied data

```
Intended:  [buffer: 16 bytes                ]
Actual:    [buffer: 16 bytes                ][17 bytes written past the end]
            \_______________ 33 bytes copied total ________________/
```

## Think About It

**28. What does it mean to write beyond the end of a buffer?**
The program writes to memory addresses that were never allocated for that variable — in this case, 17 bytes past the 16-byte `buffer`, into whatever the compiler placed next on the stack (another local variable, saved registers, or the saved return address).

**29. Why is memory corruption a security problem?**
Because the CPU has no idea the write was "wrong" — it just stores bytes at an address. If an attacker controls the *input* (here, `strlen(input)` and its contents), they control what gets written past the buffer and potentially overwrite data that affects control flow (like a return address), which is how a parsing bug becomes code execution.

**30. Why is a bounds-checked operation safer?**
A bounds-checked copy (e.g. `strncpy`/`memcpy` with a length clamped to the destination's actual size, or a safer abstraction like `std::string`/`snprintf`) refuses to write past the destination, converting a silent memory-safety violation into a detectable, handled condition (truncation, a return code, or an explicit error) instead of undefined behavior.

## Evidence to submit
- [x] Compiler output (above / `compiler_run_output.png`).
- [x] Observed program behavior: ran to completion, no visible crash.
- [x] Diagram showing intended buffer boundary vs copied data (above).

## Concept
Stack-based buffer overflow: writing past a fixed-size stack buffer corrupts adjacent stack memory, whose contents the attacker may be able to influence.

## Defense
Use bounds-checked copy functions, enable compiler warnings-as-errors for overflow diagnostics, and rely on the runtime protections inspected in Mission 11 (stack canary, NX, ASLR) as defense in depth for the cases static analysis doesn't catch.

## Verification
The compiler's own `-Wstringop-overflow` warning is itself a form of verification — it proves the unsafe call was detected before the program ever ran.

## Reflection
Without any of these defenses, this exact overflow — on a build without `-fstack-protector` — could silently overwrite a saved return address instead of landing harmlessly, which is exactly the scenario Mission 11's stack canary exists to catch.
