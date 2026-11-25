# Mission 16: Build Your First Container Sandbox

## Objective
Run a minimal Ubuntu container and observe namespace-based resource isolation (PID, mount) versus the host.

**Script:** `missions/mission16/run.sh` · **Raw output:** `evidence/mission16/output.txt` (transcribed from `docker_run_output.png` — the team's real VM run), plus a genuinely re-run `evidence/mission16/output_macos_supplement.txt` (Docker Desktop on macOS, same `--rm ubuntu` container behavior, included here only as a secondary confirmation that PID-namespace isolation is a kernel feature and not VM-specific).

## Question
When a container runs `ps`, does it see the host's full process list, or only its own?

## Prediction
Docker gives each container its own PID namespace, so `ps` inside the container should show only the container's own processes (its init process plus whatever it ran), numbered starting from PID 1 — completely different from the host's `ps`, which would show hundreds of processes.

## Experiment
```bash
docker run --rm ubuntu:26.04 uname -a
docker run --rm ubuntu:26.04 cat /etc/os-release
docker run --rm ubuntu:26.04 ps
```

## Observation
```
$ docker run --rm ubuntu:26.04 uname -a
Linux c7e63875af91 7.0.0-43-generic ... x86_64 GNU/Linux

$ docker run --rm ubuntu:26.04 cat /etc/os-release
PRETTY_NAME="Ubuntu 26.04.1 LTS"
...

$ docker run --rm ubuntu:26.04 ps
    PID TTY          TIME CMD
      1 ?        00:00:00 ps
```
Confirming the prediction: inside the container, `ps` only sees **PID 1**, which is the `ps` command itself — not the host's init, not any other host process. The hostname (`c7e63875af91`) is also a container-generated ID, distinct from the VM's own hostname (`sos-vm`) — another namespace (UTS) in action. `uname -a` reports the *host's* kernel version, though, because containers share the host kernel; they don't run their own kernel the way a VM does.

## Think About It

**47. Why does the container have its own process view?**
Docker places the container's processes in a new **PID namespace**. Inside that namespace, the first process the container runs is renumbered to PID 1, and the namespace's process-list APIs (what `ps` reads from `/proc`) only enumerate processes that belong to that namespace — the host's processes simply aren't visible from inside it.

**48. Is a container the same thing as a virtual machine?**
No. A VM (Mission 21) virtualizes hardware and runs an entirely separate guest kernel on top of a hypervisor. A container shares the **host's kernel** and is isolated using kernel features (namespaces for view isolation, cgroups for resource limits) — which is why `uname -a` inside the container still reports the host's real kernel version, not a separate "container kernel."

**49. Which resources can cgroups control?**
CPU time/shares, memory (with hard limits and OOM behavior), block I/O bandwidth, and the number of processes/PIDs a container may create — the resource-management half of container isolation, complementary to namespaces' visibility isolation.

## Evidence to submit
- [x] Container output (above).
- [x] Host vs container architecture diagram:

```
 VM / bare metal                      Container
┌─────────────────────┐              ┌─────────────────────┐
│ Container processes  │              │ VM guest processes    │
├─────────────────────┤              ├─────────────────────┤
│ Host kernel          │◀─shared──────│ (own guest kernel)    │
│ (namespaces/cgroups) │              │ Hypervisor             │
│ Host OS               │              │ Host OS                │
│ Host hardware         │              │ Host hardware           │
└─────────────────────┘              └─────────────────────┘
       Container: shares host kernel        VM: full separate kernel
```
- [x] VM vs container comparison: a VM gets a full, independently-patchable kernel and much stronger isolation (different kernel entirely) at the cost of more overhead per instance; a container is far lighter (shares the host kernel, starts in milliseconds) but a kernel-level vulnerability can potentially affect every container on that host, since they all trust the same kernel.

## Concept
Namespaces (PID, UTS, mount, network, …) give each container its own *view* of system resources; cgroups separately bound how much of the *real* resources it can consume — together these are the mechanism behind "containers," not a separate kernel.

## Defense
Least privilege at the container boundary: run containers without `--privileged`, drop unneeded Linux capabilities, and apply seccomp/AppArmor profiles (Mission 17) on top of the namespace/cgroup isolation shown here.

## Verification
The container's `ps` output (PID 1 only) is itself the verification that PID-namespace isolation is active — if it instead showed the host's full process list, that would indicate the container was *not* properly isolated (e.g. run with `--pid=host`).

## Reflection
Because containers share the host kernel, namespace/cgroup isolation is a *software* boundary enforced entirely by that one kernel — unlike the VM's hardware-assisted hypervisor boundary from Mission 21, a kernel bug here is a much shorter path from "contained" to "not contained."
