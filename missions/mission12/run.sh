#!/usr/bin/env bash
# Mission 12: The Secret File — directory hierarchy with deliberate access rules
# Run inside the lab VM only (after Mission 7 created alice/bob):
#   bash missions/mission12/run.sh
# Output is saved to evidence/mission12/output.txt

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
OUT="$ROOT/evidence/mission12/output.txt"
mkdir -p "$(dirname "$OUT")"
exec > >(tee "$OUT") 2>&1

run() { echo; echo "\$ $*"; eval "$@"; }

echo "# Mission 12 run on $(hostname) at $(date -Is) as $(whoami)"

for u in alice bob; do
    id "$u" >/dev/null 2>&1 || sudo useradd -m -s /bin/bash "$u"
done

echo; echo "## 1. Build the hierarchy (handout starter code)"
run sudo groupadd -f securelab
run sudo usermod -aG securelab alice
run sudo mkdir -p /opt/securelab/{public,employees,secrets}
run "echo 'Incident 2026-001: suspicious login on lab VM' | sudo tee /opt/securelab/secrets/incident.txt >/dev/null"
run "echo 'Welcome to SecureLab' | sudo tee /opt/securelab/public/readme.txt >/dev/null"
run "echo 'Staff rota' | sudo tee /opt/securelab/employees/rota.txt >/dev/null"
run sudo chown -R root:securelab /opt/securelab
run sudo chmod 755 /opt/securelab
run sudo chmod 755 /opt/securelab/public
run sudo chmod 644 /opt/securelab/public/readme.txt
run sudo chmod 750 /opt/securelab/employees
run sudo chmod 640 /opt/securelab/employees/rota.txt
run sudo chmod 750 /opt/securelab/secrets
run sudo chmod 640 /opt/securelab/secrets/incident.txt

run id alice
run id bob
run ls -ld /opt/securelab /opt/securelab/public /opt/securelab/employees /opt/securelab/secrets
run ls -l /opt/securelab/secrets/incident.txt

echo; echo "## 2. Access tests — alice (member of securelab)"
run sudo -u alice cat /opt/securelab/public/readme.txt
run sudo -u alice ls /opt/securelab/secrets
run sudo -u alice cat /opt/securelab/secrets/incident.txt
run "sudo -u alice bash -c 'echo tamper >> /opt/securelab/secrets/incident.txt' || echo \"[exit \$?] WRITE DENIED (group has r only)\""

echo; echo "## 3. Access tests — bob (not in securelab => 'other')"
run sudo -u bob cat /opt/securelab/public/readme.txt
run "sudo -u bob ls /opt/securelab/employees || echo \"[exit \$?] LIST DENIED\""
run "sudo -u bob ls /opt/securelab/secrets || echo \"[exit \$?] LIST DENIED\""
run "sudo -u bob cat /opt/securelab/secrets/incident.txt || echo \"[exit \$?] READ DENIED\""
run "sudo -u bob touch /opt/securelab/public/bob.txt || echo \"[exit \$?] CREATE DENIED (public is read-only for others)\""

echo; echo "## 4. Directory permission matters: make the file world-readable, bob is STILL blocked"
run sudo chmod 644 /opt/securelab/secrets/incident.txt
run ls -l /opt/securelab/secrets/incident.txt
run "sudo -u bob cat /opt/securelab/secrets/incident.txt || echo \"[exit \$?] READ DENIED (no x on secrets/ for others)\""

echo; echo "## 5. ...but if the directory is also opened up, the secret leaks"
run sudo chmod 755 /opt/securelab/secrets
run "sudo -u bob cat /opt/securelab/secrets/incident.txt && echo '!!! LEAKED to bob'"

echo; echo "## 6. Restore least-privilege design and re-verify"
run sudo chmod 750 /opt/securelab/secrets
run sudo chmod 640 /opt/securelab/secrets/incident.txt
run ls -ld /opt/securelab/secrets
run ls -l /opt/securelab/secrets/incident.txt
run "sudo -u bob cat /opt/securelab/secrets/incident.txt || echo \"[exit \$?] READ DENIED\""
run sudo -u alice cat /opt/securelab/secrets/incident.txt
