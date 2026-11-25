# Mission 17: Linux Says No

## Objective
Observe AppArmor's mandatory access control (MAC) layer: which profiles are loaded, what mode they run in, and how that differs from the discretionary permissions (DAC/ACLs) used in Missions 7–9.

**Script:** `missions/mission17/run.sh` · **Raw output:** `evidence/mission17/output.txt` (transcribed from `aa-status_1.png` .. `aa-status_4.png` — the team's real VM run).

## Question
Is AppArmor actually active and enforcing on this system, and if so, on what?

## Prediction
`aa-status` should report the module loaded with a mix of profiles in different modes: some in `enforce` (actively blocking disallowed actions), some in `complain` (logging only), and many installed applications with no profile at all (unconfined) — because AppArmor on Ubuntu ships with profiles for specific system services, not for every installed application by default.

## Experiment
```bash
sudo aa-status
sudo aa-unconfined 2>/dev/null | head -20
```

## Observation
```
apparmor module is loaded.
122 profiles are loaded.
26 profiles are in enforce mode.
6 profiles are in complain mode.
0 profiles are in prompt mode.
0 profiles are in kill mode.
90 profiles are in unconfined mode.
3 processes have profiles defined.
3 processes are in enforce mode.
   /usr/sbin/cups-browsed (982)
   /usr/sbin/cupsd (950)
   /usr/sbin/rsyslogd (678) rsyslogd
```
Confirms the prediction exactly: AppArmor is loaded and actively enforcing on a specific set of system-facing services (`cupsd`, `rsyslogd`, `NetworkManager`'s DHCP helper, `dhclient`, `docker-default`, …), a smaller set is in complain/logging-only mode (mostly LibreOffice and Transmission components), and the large majority of desktop applications (browsers, Discord, VS Code, Steam, …) have **no** profile at all — "unconfined" here doesn't mean "allowed everything explicitly," it means AppArmor simply isn't mediating them, so ordinary DAC permissions are all that constrain them.

## Think About It

**50. What is AppArmor controlling?**
Per-program access to specific resources — which files a profiled program may read/write/execute, which capabilities it may use, which network operations it may perform — regardless of what the Unix file permissions would otherwise allow. `rsyslogd`, for instance, is enforced even though its own process is running as a privileged user that DAC alone would let touch far more of the filesystem.

**51. How is policy enforcement different from ordinary Unix ownership?**
DAC (Missions 7–8) lets the *owner* of a resource decide access, and a process inherits whatever its owning user is allowed to touch. AppArmor is **mandatory**: the kernel enforces a profile's rules regardless of file ownership or whether the process is running as root — a profiled program can be denied access to a file even if its running UID would otherwise be permitted, because the policy is attached to the *program*, not negotiable by the user running it.

**52. Why can MAC provide defense in depth?**
Because it adds a second, independent check *underneath* whatever the application or its DAC permissions already allow. Even if an attacker fully compromises a profiled process (e.g. via the Mission 10/11 memory-corruption class of bug) and inherits all of that process's Unix-level permissions, AppArmor's enforce-mode profile still blocks it from doing anything the profile didn't explicitly permit — this is exactly why `docker-default` appears in the enforce list, confining what a container's processes can do beyond namespace isolation alone (Mission 16).

## Evidence to submit
- [x] AppArmor status (above / `aa-status_1.png`–`aa-status_4.png`).
- [x] One profile explanation: `docker-default` is AppArmor's baseline confinement for containers — enforced here, it restricts what a `docker run` container (Mission 16) can do even beyond the namespace/cgroup isolation, denying things like raw mount operations or writing to most of `/proc` and `/sys` even if the containerized process is running as root inside its namespace.
- [x] Allowed vs denied behaviour: no controlled denial demo was run this session (would require a test profile, per the handout's instructor note); the enforce/complain/unconfined breakdown above is the evidence captured.

## Concept
Mandatory Access Control: policy defined and enforced by the system (kernel + security module), not delegable by the resource's owner — a second, independent layer on top of DAC.

## Defense
AppArmor profiles in enforce mode for network-facing and privileged daemons (`cupsd`, `dhclient`, `rsyslogd`, `docker-default`), limiting blast radius if one of those services is compromised.

## Verification
`aa-status`'s own breakdown is the verification — it directly reports the kernel LSM's live state, not a configuration file that might not match reality.

## Reflection
The 90 unconfined applications are the honest gap here: AppArmor's protection is only as good as its profile coverage, and a desktop with mostly-unconfined applications (browsers, chat clients, IDEs) still relies on DAC and process isolation alone for most of its actual attack surface — mirroring Mission 15's point that least privilege requires deliberate profiling, not just having the mechanism installed.
