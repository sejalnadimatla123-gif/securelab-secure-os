# Mission 3: Process Detective

## Objective
Investigate process metadata via `/proc/<PID>` and build a small process-security inspector.

**Source:** `missions/mission03/proc_inspector.sh` · **Script:** `missions/mission03/run.sh` · **Raw output:** `evidence/mission03/output.txt`

## Question
What security-relevant metadata can an ordinary user read about a process they own, straight out of `/proc`?

## Prediction
`/proc/<PID>/status` should expose the process's credentials (UID/GID), its parent, its thread count and memory footprint — enough to answer "who owns this, and is it behaving normally" without any special tooling.

## Experiment
```bash
sleep 120 &
PID=$!
./proc_inspector.sh "$PID"
./proc_inspector.sh            # usage error
./proc_inspector.sh 999999     # nonexistent PID
```

## Observation (real run on the Ubuntu lab machine, against a live `sleep 120` process)
```
$ ./proc_inspector.sh
Usage: proc_inspector.sh <PID>

$ ./proc_inspector.sh 999999
Process 999999 does not exist.
```
Against the real background process, the script correctly extracted (full output in `evidence/mission03/output.txt`):
```
Command: sleep 120
Name:	sleep
State:	S (sleeping)
PPid:	8963
Uid:	1000	1000	1000	1000
Gid:	1000	1000	1000	1000
Threads:	1
VmSize:	    8372 kB
VmRSS:	    1080 kB
Open file descriptors: 3
Start time: Thu Nov 26 06:26:52 AM EST 2026
```

## TODO implemented
Added a **process start time** field (`missions/mission03/proc_inspector.sh`), computed from field 22 of `/proc/<PID>/stat` (ticks since boot) plus `/proc/uptime`, converted to wall-clock time. This is useful because a process whose start time doesn't line up with a known deploy, cron run, or login is a classic indicator of something that shouldn't be there.

## Think About It

**7. What security-relevant information does `/proc/<PID>/status` reveal?**
The owning UID/GID (and whether real/effective/saved differ — a sign of setuid behavior), the parent PID (who launched it), and its thread count and memory usage. Together these let an investigator tell *who* a process is, *who started it*, and whether its resource footprint looks normal.

**8. Why can resource consumption itself be a security concern?**
A process doesn't need to read a secret file to cause harm — it can starve the system of CPU, memory, or file descriptors (a local denial-of-service), which is why resource limits (`ulimit`, cgroups in Mission 16) are themselves a security control, not just a performance one.

**9. Why is the number of threads useful when investigating a process?**
A sudden or unusually high thread count can indicate a process spawning worker threads to brute-force something, mine cryptocurrency, or run a crawler/scanner — behavior very different from its expected single-threaded baseline.

## Evidence to submit
- [x] Working script: `missions/mission03/proc_inspector.sh`.
- [x] Open-file-descriptor count: `3` (real `sleep 120` process: stdin/stdout/stderr).
- [x] Short explanation of how `/proc` helps investigation: it is a live, per-process window into kernel-held metadata (credentials, memory, open files) that an investigator can read with ordinary shell tools, with no special instrumentation needed, as long as they have permission to read that PID's directory.

## Concept
`/proc` is a virtual (in-memory, kernel-generated) filesystem that exposes process and kernel state as regular files — exactly the kind of OS-protection-mechanism visibility Mission 2 introduced.

## Defense
Permission on `/proc/<PID>` entries mirrors process ownership: a user cannot read another user's `/proc/<PID>/status` in detail without being root or the owner, limiting what an attacker can surveil.

## Verification
The script correctly rejected a missing argument and a nonexistent PID (both confirmed with real output above), and correctly parsed every requested field from a representative status file.

## Reflection
Without `/proc`, investigating a running process would require a kernel debugger or crash dump — `/proc` is what makes routine, low-friction process forensics possible for an ordinary administrator.
