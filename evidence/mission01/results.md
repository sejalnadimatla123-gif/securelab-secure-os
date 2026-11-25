# Mission 1: Who Are You?

## Objective
Discover that Linux associates identity information with users and processes, and compare shell identity (`id`) with process identity (`identity.c`).

**Source:** `missions/mission01/identity.c` · **Script:** `missions/mission01/run.sh` · **Raw output:** `evidence/mission01/output.txt`

> **Caveat:** `evidence/mission01/output.txt` was captured on the development machine (macOS), not the Ubuntu lab VM, as a correctness smoke test of `identity.c`. UID/GID/`getuid()` behave identically across POSIX systems, so the numbers are genuine, but before final submission re-run `bash missions/mission01/run.sh` **inside the SECURELAB-CLEAN VM** to capture the authoritative `id`/`ip a` evidence (and so UID/GID line up with the `alice`/`bob` accounts used in later missions).

## Question
What identity does the shell report for me, and does a process I start see the same identity?

## Prediction
`id` and `identity.c` should report the same real UID/GID, because the process simply inherits the credentials of the shell that forked it, and (with no setuid bit) the effective UID should equal the real UID.

## Experiment
```bash
whoami
id
groups
gcc identity.c -o identity
./identity
```

## Observation
```
$ id -u -n; id -g -n
user=user primary_group=staff

$ ./identity
Real UID      : 501
Effective UID : 501
Real GID      : 20
Effective GID : 20
```
Real UID == Effective UID and Real GID == Effective GID, confirming the prediction: `identity` is not setuid, so it runs with exactly the credentials of the shell that launched it.

## Think About It

**1. What is the difference between UID and EUID?**
The **real UID** is who actually started the process (the account that owns it, used for things like `kill` permission checks). The **effective UID** is the identity the kernel uses *right now* to decide file/resource access. They differ when a program is setuid (e.g. `passwd` is owned by root and setuid, so a normal user's real UID stays theirs but the EUID becomes 0 while it edits `/etc/shadow`).

**2. Why is authentication different from authorization?**
Authentication answers "who are you?" (e.g. a password/SSH key proves you are `alice`). Authorization answers "what are you allowed to do?" given that identity (e.g. file permissions, sudoers). `id`/`identity.c` only show the *result* of authentication (a UID/GID); whether that UID can read a given file is a separate authorization decision made per-resource.

**3. Which CIA property is affected when an unauthorized user reads a secret file?**
**Confidentiality** — data is disclosed to someone not authorized to see it, even though integrity and availability of the file are untouched.

## Evidence to submit
- [x] Output of `id` and the compiled `identity` program (`evidence/mission01/output.txt`).
- [x] Explanation of authentication vs authorization (above).
- [x] Two attack surfaces of a normal workstation:
  1. **Network-facing services** — any process listening on a socket (e.g. `sshd`) accepts untrusted input from the network without the user doing anything.
  2. **Locally-run untrusted code** — any program the user executes (downloaded binary, script, browser plugin) runs with the full real UID of that user and can touch anything that UID can touch.

## Concept
Linux ties every process to a credential set (UID/EUID/GID/EGID/supplementary groups) that the kernel consults on every access check — this is the root of DAC.

## Defense
Keep real and effective IDs equal except where a setuid binary deliberately needs to escalate (and such binaries should be as small and audited as possible — least privilege).

## Verification
`identity.c`'s printed values matched `id`'s reported UID/GID exactly, confirming no privilege escalation occurred for this unprivileged process.

## Reflection
If a process could silently change its own EUID without kernel mediation, any program could impersonate any user — DAC and least privilege would be meaningless. The kernel is the only trusted arbiter of "who is this process," which is exactly why Mission 2 (the kernel boundary) matters.
