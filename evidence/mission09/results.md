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

<!-- TODO: fill from output.txt after running in the VM -->

| Check | Result |
|---|---|
| `id` | `uid=____(____) gid=____ groups=...,27(sudo),...` |
| `sudo -l` | `(ALL : ALL) ALL` — my account may run anything as root |
| Normal shell `CapEff` | `0000000000000000` (no capabilities) |
| Root process `CapEff` | `000001ffffffffff` (all capabilities — `capsh --decode` lists ~41) |
| `getcap -r /usr/bin` | _paste lines, e.g. `/usr/bin/<name> cap_net_raw=ep`_ |
| setuid-root binaries | _e.g. `sudo`, `passwd`, `su`, `mount` ..._ |
| `systemd-resolved` | runs as user `systemd-resolve`, `CapEff` = _____ |

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
