# Mission 12: The Secret File

## Objective
Design a small directory hierarchy under `/opt/securelab` with deliberate access rules and verify them with the test accounts.

**Script:** `missions/mission12/run.sh` · **Raw output:** `evidence/mission12/output.txt`

## Question
How do ownership, groups and **directory** permissions combine to protect a sensitive file?

## Prediction
Alice (member of `securelab`) can read the incident file but not modify it. Bob (not a member) can read `public/` but cannot even list `secrets/`. Even if the file itself were world-readable, Bob would still be blocked by the directory.

## Permission Design

| Path | Owner:Group | Mode | Owner (root) | Group `securelab` (alice) | Other (bob) |
|---|---|---|---|---|---|
| `/opt/securelab` | root:securelab | `755` `drwxr-xr-x` | rwx | r-x (enter, list) | r-x (enter, list) |
| `public/` | root:securelab | `755` `drwxr-xr-x` | rwx | r-x | r-x |
| `public/readme.txt` | root:securelab | `644` | rw | r | r |
| `employees/` | root:securelab | `750` `drwxr-x---` | rwx | r-x | **none** |
| `employees/rota.txt` | root:securelab | `640` | rw | r | none |
| `secrets/` | root:securelab | `750` `drwxr-x---` | rwx | r-x | **none** |
| `secrets/incident.txt` | root:securelab | `640` `-rw-r-----` | rw | r | none |

## Experiment
Handout starter code, plus sample content in each file, then access tests as Alice and Bob (see script).

## Observation — Access Tests

| Test | alice | bob |
|---|---|---|
| `cat public/readme.txt` | Allowed | Allowed |
| `ls employees/` | not tested | **Permission denied** |
| `ls secrets/` | Allowed (`incident.txt`) | **Permission denied** |
| `cat secrets/incident.txt` | Allowed | **Permission denied** |
| append to `incident.txt` | **Permission denied** (group has `r` only) | not tested |
| `touch public/bob.txt` | — | **Permission denied** |

**Directory experiment:**

| `secrets/` | `incident.txt` | bob can read? |
|---|---|---|
| `750` | `640` | No |
| `750` | `644` (world-readable) | **No** — blocked by the directory |
| `755` | `644` | **Yes — leaked** |
| `750` | `640` (restored) | No |

- `id alice` → `groups=1001(alice),1004(securelab)`; `id bob` → `groups=1002(bob)`.
- `ls -ld` confirmed `drwxr-xr-x` for `/opt/securelab` and `public/`, and `drwxr-x---` for `employees/` and `secrets/`, all `root securelab`.
- `sudo ls -l /opt/securelab/secrets/incident.txt` confirmed the file mode at each stage: `-rw-r----- root securelab` (initial), `-rw-r--r--` (after `chmod 644`, step 4), and `-rw-r-----` again after the restore (step 6).

## Think About It

**35. Why does directory permission matter as well as file permission?**
To open `/opt/securelab/secrets/incident.txt` the kernel must resolve every component of the path, and that requires **execute (search)** permission on each directory. `secrets/` is `750`, so "other" has no `x` and Bob's path lookup fails before the file's own mode is checked. Our test proved it: with the file at `644` Bob was still denied; only after the directory was also opened (`755`) did the secret leak. On directories, `r` = list names, `w` = create/delete/rename entries, `x` = traverse.

**36. Who should read the incident file?**
Only the incident-response team — members of `securelab` (here, Alice) — plus root as administrator. They need read but not write, so the group gets `r` only; write stays with root, which preserves the record's integrity.

**37. What would happen if the file were world-readable?**
Any local user or compromised service could read incident details (confidentiality breach), possibly learning which weaknesses are under investigation. In our layout the `750` directory still blocked this — **defense in depth** — but one more mistake (opening the directory) leaked it, as step 5 showed.

## Least-Privilege Explanation
Each class gets the minimum needed: the public area is readable by all but writable by none except root; employee and secret areas are invisible to non-members; group members can read the incident report but not alter it. Membership in `securelab`, not individual file edits, is the single point where access is granted or revoked.

## Concept
Ownership, groups, directory traversal permission, least privilege, defense in depth.

## Defense
Restrictive directory modes (`750`) plus restrictive file modes (`640`), with access granted via group membership.

## Verification
Bob was denied listing and reading under `secrets/` and `employees/`; Alice could read but not write; the restored design denied Bob again.

## Reflection
Without the directory restriction, a single careless `chmod 644` on a file would expose it. Relying on two independent layers (directory + file) means one mistake doesn't immediately leak data.
