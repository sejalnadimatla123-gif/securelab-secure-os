# Mission 18: Compare Access-Control Models

## Objective
Construct a conceptual map of access-control mechanisms from what we observed in earlier missions.

## Comparison Table

| Mechanism | Decision basis | Example from our lab | Limitation |
|---|---|---|---|
| **DAC** (owner/group/other) | Requester's UID/GIDs vs file's owner, group and mode bits; **owner** sets the policy | M7: `chmod 600` on `/tmp/alice_secret.txt` denied Bob; Alice changed the mode herself without sudo | Only one owner + one group; owner can make mistakes or leak data deliberately; root bypasses it; malware running as the user inherits all the user's rights |
| **ACLs** | Same DAC check extended with named-user/named-group entries, bounded by a mask | M8: `setfacl -m u:bob:r` gave Bob alone read access to a `600` file | Hidden behind `+` in `ls -l`, harder to audit; may be lost by tools that don't preserve ACLs; still discretionary |
| **MAC** (AppArmor/SELinux) | System-wide policy written by the administrator, attached to a program (profile) or label; enforced regardless of owner | M17: `aa-status` showed profiles in enforce mode confining specific programs even when DAC would allow access | Policies are complex to write and debug; too permissive is useless, too strict breaks apps; AppArmor is path-based |
| **RBAC** | The **role(s)** a user holds; permissions attach to roles, users are assigned roles | M12: group `securelab` acted as an "incident responder" role — adding Alice to the group granted access to `secrets/` and `employees/` | Linux has no native full RBAC (groups/sudo approximate it); role explosion; roles need regular review as people change jobs |
| **Capabilities** | Whether the process holds a specific privilege bit (`CAP_NET_RAW`, ...) instead of whether EUID = 0 | M9: normal shell `CapEff = 0`, root has all ~41; `getcap` shows binaries with single capabilities | Some capabilities are nearly root-equivalent (`CAP_SYS_ADMIN`, `CAP_DAC_OVERRIDE`); misassigning file capabilities creates privilege-escalation holes |

## One Realistic Scenario per Mechanism

- **DAC:** A developer keeps an SSH private key in `~/.ssh/id_ed25519` with mode `600`, so other users on a shared server can't read it. `ssh` even refuses to use a key with looser permissions.
- **ACLs:** A teaching assistant needs read access to one professor's `grades.csv` without joining the `faculty` group, which would expose every faculty file → `setfacl -m u:ta:r grades.csv`.
- **MAC:** A web server is compromised through a plugin bug. Its process runs as `www-data`, and DAC would let it read world-readable files like `/home/*/notes.txt`, but its AppArmor profile only allows `/var/www/**` and its logs, so the attacker is confined.
- **RBAC:** A company defines a `dbadmin` role with permission to restart PostgreSQL and read its configs and logs (e.g. a `dbadmin` group + `sudoers` rule `%dbadmin ALL=(root) /usr/bin/systemctl restart postgresql`). New DBAs get the role; leavers have it removed, with no per-file edits.
- **Capabilities:** A web server must bind port 443 (< 1024 normally requires root). Instead of running it as root, it gets only `CAP_NET_BIND_SERVICE` (`AmbientCapabilities=CAP_NET_BIND_SERVICE` in its systemd unit), so a compromise doesn't hand over the whole machine.

## Think About It

**53. For DAC, who normally controls the access decision?**
The **owner** of the object. In M7 Alice changed her own file's mode without sudo, and Bob could not.

**54. For MAC, who defines the policy?**
The **system administrator / security policy authority**, not the file owner. Users (even a file's owner) cannot override it; AppArmor profiles are loaded by root and enforced by the kernel.

**55. How would RBAC express a role such as "database administrator"?**
Define a role `dbadmin`, attach the needed permissions to it (start/stop the DB service, read/write DB config and data dirs, read DB logs), then assign users to the role. On Linux this is approximated with a `dbadmin` group owning those files plus a `sudoers` rule granting only the DB management commands to `%dbadmin`.

**56. What is the security idea behind a capability?**
Break root's all-or-nothing power into small, independent privileges and give a process only the ones it needs (least privilege). The kernel checks for the specific capability instead of UID 0, so a compromised process gains only that narrow power.

**57. How do ACLs complement traditional permissions?**
They keep the owner/group/other model but allow extra named-user and named-group entries, so you can grant one more person access without changing the group or opening "other". The ACL mask caps what those extra entries can grant.

## How the Layers Fit Together

```
 process requests open("/opt/securelab/secrets/incident.txt", O_RDONLY)
        │
        ▼
 ┌─────────────────────┐   capabilities: does it hold CAP_DAC_OVERRIDE? (root bypass)
 │ 1. DAC + ACL check  │── owner / named users / group ∩ mask / other     (M7, M8, M12)
 └─────────┬───────────┘   RBAC approximated by group membership          (M12)
           │ allowed
           ▼
 ┌─────────────────────┐
 │ 2. MAC (AppArmor)   │── does the program's profile allow this path?    (M17)
 └─────────┬───────────┘
           │ allowed
           ▼
        file opened          ← both layers must say yes: defense in depth
```
