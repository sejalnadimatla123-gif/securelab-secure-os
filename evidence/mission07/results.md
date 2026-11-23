# Mission 7: Alice vs Bob

## Objective
Discover discretionary access control (DAC) by creating two users and testing whether Bob can read a file owned by Alice.

**Script:** `missions/mission07/run.sh` · **Raw output:** `evidence/mission07/output.txt`

## Question
Can one ordinary user read another user's file, and who decides?

## Prediction
With the default umask (`022`), Alice's new file will be created as `-rw-r--r--`, so Bob will be able to read it. After `chmod 600`, only Alice (and root) should be able to read it.

## Experiment

```bash
sudo useradd -m -s /bin/bash alice
sudo useradd -m -s /bin/bash bob
sudo -u alice bash -c 'echo "Alice secret" > /tmp/alice_secret.txt'
sudo chown alice:alice /tmp/alice_secret.txt
ls -l /tmp/alice_secret.txt
sudo -u bob cat /tmp/alice_secret.txt
sudo chmod 600 /tmp/alice_secret.txt
ls -l /tmp/alice_secret.txt
sudo -u bob cat /tmp/alice_secret.txt
```

The script additionally tests Bob writing to the file, and shows that Alice (the owner) can change the mode herself while Bob cannot.

## Observation

| Step | Mode | Bob read | Bob write | Alice read |
|---|---|---|---|---|
| Before `chmod 600` | `-rw-rw-r-- alice alice` | Allowed (`Alice secret`) | Denied (`Permission denied`) | not tested |
| After `chmod 600` | `-rw------- alice alice` | **Denied** (`Permission denied`) | not tested | Allowed (`Alice secret`) |

- `umask` printed `0002`, **not** `022` as predicted, so the file was created as `-rw-rw-r--` (`664`) rather than `-rw-r--r--`. The prediction that Bob could read it still held, because "other" had `r--` either way.
- Alice ran `chmod 640` (→ `-rw-r-----`) and `chmod 600` (→ `-rw-------`) on her own file **without sudo**, and both were allowed.
- Bob running `chmod 644` on Alice's file got `chmod: changing permissions of '/tmp/alice_secret.txt': Operation not permitted`.

## Owner / Group / Other

Every file has one owning user, one owning group and three permission triplets:

```
-rw-rw-r--   alice  alice      (observed, umask 0002)
 │└┬┘└┬┘└┬┘
 │ │  │  └─ other : everyone else (Bob)          → r--
 │ │  └──── group : members of group "alice"      → rw-
 │ └─────── owner : alice                          → rw-
 └───────── file type (- = regular file)
```

The kernel checks the categories in order and uses the **first** one that matches: if you are the owner, only the owner bits apply; otherwise, if you are in the group, only the group bits apply; otherwise the "other" bits apply. Bob is neither the owner nor in group `alice`, so the "other" bits decide his access.

## Think About It

**19. Why did Bob's access change after `chmod 600`?**
`600` = `rw-------`. The "other" triplet changed from `r--` to `---`. Bob falls into the "other" class, so when he calls `open()` the kernel finds no read bit and returns `EACCES` (Permission denied).

**20. Who controls the discretionary permission on this file?**
The **owner** (Alice) — that is what makes it *discretionary*: access is at the owner's discretion. Alice changed the mode without sudo, while Bob could not. Root can also override, because root bypasses DAC checks.

**21. How does this experiment demonstrate least privilege?**
The secret only needs to be read by Alice, so `600` grants exactly that and nothing more. The default `664` (from umask `0002`) gave every user on the system read access they had no need for.

## Concept
Discretionary Access Control: the kernel mediates every `open()` against the file's owner/group/mode, and the owner sets that policy.

## Defense
Restrictive file modes (`600`/`640`) and a restrictive umask (e.g. `077` for private data).

## Verification
Bob's `cat` returned `Permission denied` after the change, while Alice could still read the file.

## Reflection
Without the restriction, any local account — including a compromised service account — could read Alice's secret, a confidentiality failure. DAC's weakness is that it relies on owners making good choices: Alice could just as easily `chmod 644` it again.
