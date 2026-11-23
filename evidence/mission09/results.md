# Mission 9: Too Much Power

## Objective
Investigate how Linux can express privileges more narrowly than full root access.

**Script:** `missions/mission09/run.sh` (read-only, adds no capabilities) · **Raw output:** `evidence/mission09/output.txt`

## Question
Does a program need *all* of root's power, or can it be given only the one privilege it needs?

## Prediction
My normal shell will have an empty effective capability set, while a root process will have every capability. A few binaries in `/usr/bin` will carry a single file capability instead of being setuid-root.

## Experiment

```bash
sudo apt install -y libcap2-bin
id
sudo -l
capsh --print | head -40
getcap -r /usr/bin 2>/dev/null | head -20
```

Additionally: compare `CapEff` in `/proc/self/status` for a normal vs a root process, list setuid-root binaries, and inspect a system service (`systemd-resolved`) that runs as its own non-root user.

## Observation

| Check | Result |
|---|---|
| `id` | `uid=1000(home) gid=1000(home) groups=1000(home),4(adm),24(cdrom),27(sudo),30(dip),46(plugdev),122(lpadmin),135(lxd),136(sambashare)` |
| `sudo -l` | `(ALL : ALL) ALL` — my account may run anything as root |
| Normal shell `CapEff` | `0000000000000000` (no capabilities) |
| Root process `CapEff` | `000001ffffffffff` (all capabilities — `capsh --decode` lists 41, `cap_chown` … `cap_checkpoint_restore`) |
| `getcap -r /usr/bin` | `/usr/bin/ping cap_net_raw=ep`, `/usr/bin/mtr-packet cap_net_raw=ep` (also in `/usr/lib`: `gst-ptp-helper cap_net_bind_service,cap_net_admin=ep`, `snap-confine` with 10 caps `=p`) |
| setuid-root binaries | `mount`, `su`, `gpasswd`, `sudo`, `umount`, `newgrp`, `chfn`, `pkexec`, `chsh`, `passwd`, `fusermount3`, `/usr/sbin/pppd` (12) |
| `systemd-resolved` | PID 514 runs as user `systemd-resolve` (UID `101`), `CapEff` = `0000000000002000` = `cap_net_raw` only |

## Broad vs Narrow Privilege

```
 BROAD: setuid-root / run as root                NARROW: capabilities
 ┌───────────────────────────────┐              ┌───────────────────────────────┐
 │ program (EUID 0)              │              │ program (EUID = normal user)  │
 │  CAP_NET_RAW        ✔         │              │  CAP_NET_RAW        ✔         │
 │  CAP_NET_BIND_SERVICE ✔       │              │  CAP_NET_BIND_SERVICE ✘       │
 │  CAP_DAC_OVERRIDE   ✔ (read   │              │  CAP_DAC_OVERRIDE   ✘         │
 │                      any file)│              │  CAP_SYS_ADMIN      ✘         │
 │  CAP_SYS_ADMIN      ✔         │              │  CAP_SYS_MODULE     ✘         │
 │  CAP_SYS_MODULE     ✔ (load   │              │  ... 40 others      ✘         │
 │                  kernel code) │              │                               │
 │  ... all ~41        ✔         │              │                               │
 └──────────────┬────────────────┘              └──────────────┬────────────────┘
                │ bug exploited                                │ bug exploited
                ▼                                              ▼
       attacker = full root                       attacker = can send raw packets,
       (read /etc/shadow, load modules,           still cannot read other users'
        own the whole machine)                    files or touch the kernel
```

## Think About It

**25. Why is giving every program root privileges dangerous?**
Root bypasses all DAC checks and holds every capability. Any bug in any root program (buffer overflow, injection, bad input parsing) instantly becomes a full-system compromise: reading `/etc/shadow`, installing backdoors, loading kernel modules. Running everything as root maximises the blast radius of every bug.

**26. What is the idea behind a capability?**
Linux splits root's power into ~41 independent privileges (`CAP_NET_RAW`, `CAP_NET_BIND_SERVICE`, `CAP_DAC_OVERRIDE`, `CAP_SYS_ADMIN`, ...). A process or file is given only the specific capabilities it needs, so the kernel checks "does this process hold `CAP_X`?" instead of "is UID 0?". Our normal shell's empty `CapEff` vs root's full mask shows this directly.

**27. How can privilege separation reduce the impact of a compromised component?**
Splitting a system into components that each run with only the privilege they need (e.g. `systemd-resolved` as its own user, sshd's unprivileged pre-auth child) means compromising one component yields only that component's limited rights, not the whole machine. The attacker must find a second vulnerability to escalate.

## Concept
Least privilege, capabilities, privilege separation.

## Defense
Prefer file/ambient capabilities or dedicated service users over setuid-root; limit `sudo` rules to specific commands.

## Verification
`CapEff` comparison shows the normal shell holds none of root's privileges; `getcap` shows binaries that receive one capability instead of full root.

## Reflection
`sudo -l` showing `(ALL : ALL) ALL` means my own account is effectively one password away from full root — a stolen password is enough to own the VM. Narrow `sudoers` rules would reduce that.
