#!/usr/bin/env bash
# Mission 7: Alice vs Bob — discretionary access control (DAC)
# Run inside the lab VM only:  bash missions/mission07/run.sh
# Output (commands + results) is saved to evidence/mission07/output.txt

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
OUT="$ROOT/evidence/mission07/output.txt"
mkdir -p "$(dirname "$OUT")"
exec > >(tee "$OUT") 2>&1

run() { echo; echo "\$ $*"; eval "$@"; }

echo "# Mission 7 run on $(hostname) at $(date -Is) as $(whoami)"

# Test users (no password needed: we switch to them with sudo -u)
for u in alice bob; do
    id "$u" >/dev/null 2>&1 || sudo useradd -m -s /bin/bash "$u"
done
run id alice
run id bob

echo; echo "## 1. Alice creates a file (default umask)"
run sudo rm -f /tmp/alice_secret.txt
run "sudo -u alice bash -c 'echo \"Alice secret\" > /tmp/alice_secret.txt'"
run sudo chown alice:alice /tmp/alice_secret.txt
run umask
run ls -l /tmp/alice_secret.txt

echo; echo "## 2. Bob tries to read / write BEFORE chmod 600"
run "sudo -u bob cat /tmp/alice_secret.txt || echo \"[exit \$?] READ DENIED\""
run "sudo -u bob bash -c 'echo bob-was-here >> /tmp/alice_secret.txt' || echo \"[exit \$?] WRITE DENIED\""

echo; echo "## 3. Owner restricts the file to owner-only (600)"
run sudo chmod 600 /tmp/alice_secret.txt
run ls -l /tmp/alice_secret.txt
run stat -c "'%A %U:%G %n'" /tmp/alice_secret.txt

echo; echo "## 4. Bob tries again AFTER chmod 600"
run "sudo -u bob cat /tmp/alice_secret.txt || echo \"[exit \$?] READ DENIED\""

echo; echo "## 5. Alice (owner) can still read"
run sudo -u alice cat /tmp/alice_secret.txt

echo; echo "## 6. DAC is discretionary: Alice herself can change the mode (no sudo)"
run sudo -u alice chmod 640 /tmp/alice_secret.txt
run ls -l /tmp/alice_secret.txt
run "sudo -u bob chmod 644 /tmp/alice_secret.txt || echo \"[exit \$?] BOB CANNOT CHANGE PERMISSIONS (not owner)\""
run sudo -u alice chmod 600 /tmp/alice_secret.txt
run ls -l /tmp/alice_secret.txt
