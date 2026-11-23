#!/usr/bin/env bash
# Mission 8: The Permission Maze — POSIX ACLs
# Run inside the lab VM only (after Mission 7 created alice/bob):
#   bash missions/mission08/run.sh
# Output is saved to evidence/mission08/output.txt

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
OUT="$ROOT/evidence/mission08/output.txt"
mkdir -p "$(dirname "$OUT")"
exec > >(tee "$OUT") 2>&1

run() { echo; echo "\$ $*"; eval "$@"; }

echo "# Mission 8 run on $(hostname) at $(date -Is) as $(whoami)"

command -v setfacl >/dev/null || sudo apt install -y acl
for u in alice bob; do
    id "$u" >/dev/null 2>&1 || sudo useradd -m -s /bin/bash "$u"
done

echo; echo "## 1. Owner-only file (600), no ACL yet"
run sudo rm -f /tmp/acl_secret.txt
run "sudo -u alice bash -c 'echo \"ACL test\" > /tmp/acl_secret.txt'"
run sudo chown alice:alice /tmp/acl_secret.txt
run sudo chmod 600 /tmp/acl_secret.txt
run ls -l /tmp/acl_secret.txt
run getfacl /tmp/acl_secret.txt
run "sudo -u bob cat /tmp/acl_secret.txt || echo \"[exit \$?] READ DENIED\""

echo; echo "## 2. Grant ONLY bob read access via an ACL entry"
run sudo setfacl -m u:bob:r /tmp/acl_secret.txt
run getfacl /tmp/acl_secret.txt
run "ls -l /tmp/acl_secret.txt   # note the '+' after the mode bits"
run sudo -u bob cat /tmp/acl_secret.txt

echo; echo "## 3. The ACL grants read only — bob still cannot write"
run "sudo -u bob bash -c 'echo bob >> /tmp/acl_secret.txt' || echo \"[exit \$?] WRITE DENIED\""

echo; echo "## 4. 'other' users are still denied (ACL is per-user, not world)"
id carol >/dev/null 2>&1 || sudo useradd -m -s /bin/bash carol
run "sudo -u carol cat /tmp/acl_secret.txt || echo \"[exit \$?] READ DENIED for carol\""

echo; echo "## 5. Revoke the ACL entry and verify bob is denied again"
run sudo setfacl -x u:bob /tmp/acl_secret.txt
run getfacl /tmp/acl_secret.txt
run "sudo -u bob cat /tmp/acl_secret.txt || echo \"[exit \$?] READ DENIED\""
