# Mission 15: The Suspicious Application

## Objective
Identify what resources `/usr/bin/drawing` (GNOME's drawing/annotation utility) can access, and decide what it actually needs.

**Raw output:** `evidence/mission15/output.txt` (transcribed from `ps_output.png`, `fd_list.png` — the team's real VM run).

## Question
Does a simple drawing application need everything the kernel is letting it have access to?

## Prediction
A drawing tool fundamentally needs to read/write image files and talk to the display server — it should **not** need camera, microphone, or unrestricted network access. We expect to see stdio redirected to `/dev/null` (GUI apps commonly detach from the launching terminal), some `eventfd`s (GLib/GTK's event-loop plumbing), and a handful of local sockets (display server / D-Bus), but no obviously excessive access.

## Experiment
```bash
ps -p <PID> -o pid,ppid,uid,euid,nlwp,%cpu,%mem,cmd
ls -l /proc/<PID>/fd
cat /proc/<PID>/status | grep -E 'Name|Uid|Gid|Threads'
ss -lntup
```

## Observation
```
  PID  PPID  UID  EUID NLWP %CPU %MEM CMD
 3067  1652 1000  1000    6  1.0  3.8 /usr/bin/python3 /usr/bin/drawing
```
6 threads, real UID == effective UID (no privilege escalation), modest CPU/memory. The file-descriptor table showed fd 0/1/2 pointed at `/dev/null` (not a terminal — confirms it detached as a GUI app), several `anon_inode:[eventfd]` entries (GLib/GTK main-loop timers), and several local Unix-domain `socket:[…]` entries (the display server / portal / D-Bus connections GTK apps use) — no raw network sockets, no access to `/dev/video*` or `/dev/snd/*` (camera/microphone), consistent with the prediction.

## Application resource table

| Resource | Needed? | Observed |
|---|---|---|
| Filesystem (read/write image files) | Yes | implied by its purpose; not directly visible in this fd snapshot |
| Display server / D-Bus sockets | Yes | several `socket:[…]` fds present |
| Event loop (`eventfd`) | Yes (implementation detail of GTK) | multiple `anon_inode:[eventfd]` fds |
| `/dev/null` (detached stdio) | Harmless | fd 0/1/2 |
| Network (general) | No | no network sockets observed |
| Camera / microphone | No | not observed |
| Unbounded CPU/RAM | No | should be capped, not observed as restricted |

## Think About It

**44. Which resources does your chosen application actually need?**
The filesystem (to open/save drawings), the display-server connection, and its own event-loop plumbing (`eventfd`). Nothing about "drawing on an image" requires network, camera, or microphone access.

**45. Which resources could be denied without breaking its purpose?**
Network access, camera, and microphone entirely; and CPU/RAM could be throttled to reasonable bounds without affecting normal use, since a drawing tool has no legitimate need for unbounded resource consumption.

**46. How does least privilege reduce attack surface?**
If this process were compromised (e.g. via a malicious image file triggering a parser bug), a sandbox that had already denied network/camera/microphone access would prevent that compromise from exfiltrating data or spying on the user — the blast radius of the bug is capped by what the process was *allowed* to touch, not just by the bug's own severity.

## Evidence to submit
- [x] Application resource table (above).
- [x] Proposed sandbox policy: confine to a private, isolated filesystem path (a Flatpak-style sandboxed `$HOME`), keep `/dev/null` and the display/D-Bus sockets, and mediate any other device access through the desktop portal rather than direct access.
- [x] At least three resources to restrict: network sockets, camera device, microphone device.

## Concept
Attack surface = everything a process can touch; sandboxing (Missions 16–17) is the mechanism that shrinks that surface down to only what the process's actual job requires.

## Defense
A sandboxing policy (Flatpak portals, AppArmor profile, or a container) that denies network/camera/microphone by default and only grants filesystem access through a mediated, user-approved dialog.

## Verification
`/proc/<PID>/fd` is itself the verification tool: it shows exactly what the running process currently holds open, which is a ground-truth check against whatever policy claims to be in effect.

## Reflection
Without this kind of resource inventory, "least privilege" is just a slogan — you can't meaningfully restrict an application's access until you've first measured what it actually uses, which is exactly the baseline-before-remediation workflow Mission 22's final challenge asks for.
