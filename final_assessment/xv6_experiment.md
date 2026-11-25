# Mission 22 — xv6 Experiment: Does the Guard Page Actually Stop a Stack Overflow?

Per the instructor's brief, this is the xv6/QEMU track of the final assessment:
clone MIT's teaching OS, build/run it under QEMU, and run at least one
experiment that demonstrates (and ideally improves) a Secure OS concept —
done here as our own experiment rather than from the module 5 slides.

**Environment:** this was built and run directly on macOS (Homebrew
`riscv64-elf-gcc` + `qemu-system-riscv64`), not inside the Ubuntu lab VM —
xv6 runs under QEMU's RISC-V emulation, so no VirtualBox/OVA import is
needed for this part.

**Source:** `final_assessment/xv6/xv6-riscv/` (MIT xv6-riscv, upstream,
depth-1 clone) · `user/stackbomb.c` (our addition) · raw run output in
`final_assessment/xv6_output.txt`.

## Question
xv6 is a minimal teaching kernel — does it have any equivalent of the
stack-overflow defenses covered in Mission 10/11 (NX, ASLR, stack canaries),
or will a recursive stack overflow silently corrupt adjacent memory the way
`memory_overflow_demo.c` did on an unprotected build?

## Prediction
Given xv6's small, fixed user stack (`USERSTACK` pages, `kernel/param.h`), we
expected one of two outcomes: either the overflow silently walks into
whatever is mapped below the stack (heap/BSS), corrupting it with no error —
the "bad" outcome demonstrated in Mission 10 — or xv6 maps an inaccessible
guard page directly below the stack, in which case the kernel should trap and
kill the process cleanly.

## Experiment
`user/stackbomb.c` recursively calls itself, touching a new ~512-byte local
buffer each call, so it consumes stack space far faster than a normal
program and will hit whatever lies below the stack within a few hundred
calls.

```bash
make                     # build xv6 + stackbomb with riscv64-elf-gcc
make qemu-gdb &          # or: make qemu
# at the xv6 $ prompt:
stackbomb
```

## Observation
Genuine run, `final_assessment/xv6_output.txt`:

```
$ stackbomb
stackbomb: recursing until the stack guard page faults...
depth=0 sp-ish local addr=0x0000000000003DA0
depth=1 sp-ish local addr=0x0000000000003B80
depth=2 sp-ish local addr=0x0000000000003960
depth=3 sp-ish local addr=0x0000000000003740
depth=4 sp-ish local addr=0x0000000000003520
depth=5 sp-ish local addr=0x0000000000003300
depth=usertrap(): unexpected scause 0xf pid=3
            sepc=0x40c stval=0x2ff8
$
```

Reading `kernel/exec.c`, this xv6 revision already implements the defense we
were testing for:

```c
// Allocate some pages at the next page boundary.
// Make the first inaccessible as a stack guard.
// Use the rest as the user stack.
sz = PGROUNDUP(sz);
...
uvmclear(pagetable, sz - (USERSTACK + 1) * PGSIZE);   // clears PTE_U/PTE_V on the guard page
```

`stackbomb` printed exactly 6 `depth=N` lines (each ~512-byte frame, so ~3KB
of recursion — consistent with `USERSTACK=1` page of 4KB usable stack before
hitting the guard page below it), then the kernel's own trap handler fired:
`scause 0xf` is a RISC-V store/AMO page fault, `stval=0x2ff8` is the faulting
address (landing inside the unmapped guard page just below the stack base),
and the process (pid 3, `stackbomb`) was killed. The shell's own `$` prompt
returned immediately after — confirming the kernel itself was never affected,
only the single offending process. This exactly confirms the prediction: the
guard page converts what would otherwise be silent corruption into an
immediate, isolated, cleanly-reported kill.

## Think about it (applying Mission 10/11's questions to xv6)
- **What does it mean to write beyond the end of a buffer, here?** Each
  recursive call pushes a new stack frame; once the frame pointer crosses
  below the lowest user-stack page, the *next* memory access (not a
  `memcpy`, just an ordinary load/store from the next stack frame) touches
  the guard page.
- **Why is this a security control, not just a bug catcher?** Without the
  guard page, a stack overflow would instead land on whatever's mapped
  next (heap data, in a more complex program), which is exactly the
  "write beyond the buffer corrupts adjacent memory" scenario Mission 10
  demonstrated on Linux — silent corruption is worse than a clean kill,
  because a silent corruption can potentially be steered by an attacker
  into controlling data or a return address, whereas a fault kills the
  process immediately and loudly.
- **Is this "as good as" ASLR/NX/canaries (Mission 11)?** No — it only
  catches a stack overflow that runs *past* the stack, not one that
  overwrites a saved return address *within* the current frame (classic
  stack-smashing). xv6 has no stack canary and no W^X enforcement on user
  pages beyond what `flags2perm()` sets from the ELF segment, so a
  single-frame buffer overflow that only overwrites its own frame's saved
  return address would **not** be caught by this guard page. That gap is
  the honest limitation to report.

## Proposed further hardening (reflection, not implemented)
A stack canary (a known value pushed in the prologue of any function with a
local buffer, checked before return) would catch the single-frame case the
guard page misses, at the cost of a compiler-level change (xv6 doesn't use
`-fstack-protector` today since its own minimal libc/startup code doesn't
expect it). This mirrors Mission 11's "defense in depth" point exactly:
the guard page and a stack canary catch *different* failure shapes, and a
real OS needs both, not one or the other.

## Evidence to submit
- [x] `final_assessment/xv6_output.txt` — boot log + `stackbomb` run, showing
      the kernel's page-fault/kill message.
- [x] Source of the added experiment: `user/stackbomb.c`
      (`final_assessment/xv6/stackbomb.c` + the full upstream clone under
      `final_assessment/xv6/xv6-riscv/user/stackbomb.c`, gitignored).
- [x] Concept connection and limitation analysis (above).

## Build/run notes for reproducing this
```bash
# Ubuntu (fast — prebuilt packages):
sudo apt install -y gcc-riscv64-unknown-elf qemu-system-misc

# macOS (slow — builds from source; this run also needed a manual qemu
# rebuild with --target-list=riscv64-softmmu because Homebrew's default
# qemu build fails on old macOS/Clang in unrelated ARM board code):
brew install qemu riscv64-elf-gcc riscv64-elf-binutils

cd final_assessment/xv6/xv6-riscv   # clone of mit-pdos/xv6-riscv
make
make qemu
# at the xv6 $ prompt: stackbomb
```
