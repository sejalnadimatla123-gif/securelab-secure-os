# Mission 8: The Permission Maze

## Objective
Give one additional user (Bob) read access to Alice's private file **without** changing the owner/group/other design.

**Script:** `missions/mission08/run.sh` · **Raw output:** `evidence/mission08/output.txt`

## Question
How can we grant access to exactly one extra user when owner/group/other is too coarse?

## Prediction
With mode `600`, Bob is denied. After `setfacl -m u:bob:r`, Bob can read but not write, and every other user (e.g. `carol`) is still denied.

## Experiment

```bash
sudo apt install -y acl
sudo -u alice bash -c 'echo "ACL test" > /tmp/acl_secret.txt'
sudo chown alice:alice /tmp/acl_secret.txt
sudo chmod 600 /tmp/acl_secret.txt
getfacl /tmp/acl_secret.txt
sudo setfacl -m u:bob:r /tmp/acl_secret.txt
getfacl /tmp/acl_secret.txt
sudo -u bob cat /tmp/acl_secret.txt
```

The script also tests Bob writing, a third user `carol` reading, and revoking the entry with `setfacl -x u:bob`.

## Observation

**Before** (`ls -l` → `-rw-------`):
```
# file: tmp/acl_secret.txt
# owner: alice
# group: alice
user::rw-
group::---
other::---
```

**After** `setfacl -m u:bob:r` (`ls -l` → `-rw-r-----+`):
```
# file: tmp/acl_secret.txt
# owner: alice
# group: alice
user::rw-
user:bob:r--
group::---
mask::r--
other::---
```

| User | Before ACL | After ACL | After `setfacl -x u:bob` |
|---|---|---|---|
| alice (owner) | not tested (`user::rw-`) | not tested (`user::rw-`) | not tested (`user::rw-`) |
| bob | read denied | **read allowed** (`ACL test`), write denied | read denied |
| carol (other) | not tested | read denied | not tested |

After `setfacl -x u:bob`, `getfacl` shows the `user:bob` entry removed, but a `mask::---` line remains:
```
user::rw-
group::---
mask::---
other::---
```

Note: `ls -l` shows a `+` after the mode bits, and the group bits now display the ACL **mask** (`r--`), not the owning group's permission.

## Think About It

**22. What changed when the ACL was added?**
Two entries appeared: `user:bob:r--` (a named-user entry) and `mask::r--` (the maximum permission any named user/group entry can grant). `other::---` and `group::---` were untouched, and `ls -l` gained a `+`.

**23. Why is an ACL useful when owner/group/other is insufficient?**
Classic permissions allow only one owner and one group. To give Bob alone read access we would otherwise have to create a new group, change the file's group, or open "other" to everyone. An ACL adds a single named entry for Bob, leaving everyone else's access unchanged.

**24. What security principle is being exercised?**
**Least privilege** (fine-grained authorization): Bob gets exactly read, on exactly this file, and nobody else gains anything.

## Permissions vs ACLs

Traditional Unix permissions are a fixed three-entry list — owner, one group, everyone else — which is simple, fast and easy to audit with `ls -l`, but can't express "Alice plus Bob, but not Carol" without creating a new group. POSIX ACLs extend the same DAC model with any number of named-user and named-group entries, bounded by a mask, so access can be granted per user without widening the group or "other" classes. The trade-off is visibility: ACL grants are hidden behind the `+` in `ls -l` and need `getfacl` to audit, and they can be lost by tools that copy files without preserving ACLs. Both are still *discretionary* — the file owner controls them.

## Concept
ACLs (fine-grained DAC). The kernel evaluates owner → named users → groups (∩ mask) → other.

## Defense
Grant per-user access with `setfacl` rather than widening group/other bits; revoke with `setfacl -x`.

## Verification
Bob could read only while the ACL entry existed; Carol was denied while Bob's entry was active; Bob's write was denied.

## Reflection
Without ACLs the easy shortcut is `chmod 644`, which leaks the file to every user. Forgotten ACL entries are also a risk — after a role change, Bob would keep access until someone checks `getfacl`.
