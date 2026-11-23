#!/usr/bin/env bash
# Mission 9: Too Much Power — root vs capabilities
# Read-only inspection. Does NOT add capabilities to any binary.
# Run inside the lab VM as your normal user:  bash missions/mission09/run.sh
# (sudo -l will ask for your password.)
# Output is saved to evidence/mission09/output.txt

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
OUT="$ROOT/evidence/mission09/output.txt"
mkdir -p "$(dirname "$OUT")"
exec > >(tee "$OUT") 2>&1

run() { echo; echo "\$ $*"; eval "$@"; }

echo "# Mission 9 run on $(hostname) at $(date -Is) as $(whoami)"

command -v capsh >/dev/null || sudo apt install -y libcap2-bin

echo; echo "## 1. Who am I and what may I do with sudo?"
run id
run sudo -l

echo; echo "## 2. Capabilities of my normal shell"
run "capsh --print | head -40"
run "grep -E '^Cap(Inh|Prm|Eff|Bnd|Amb)' /proc/self/status"

echo; echo "## 3. Capabilities of a root process (broad privilege)"
run "sudo grep -E '^Cap(Inh|Prm|Eff|Bnd|Amb)' /proc/self/status"
run "capsh --decode=\$(sudo awk '/^CapEff/ {print \$2}' /proc/self/status)"

echo; echo "## 4. Binaries that carry narrow file capabilities instead of setuid-root"
run "getcap -r /usr/bin 2>/dev/null | head -20"
run "getcap -r /usr/sbin /usr/lib 2>/dev/null | head -20"

echo; echo "## 5. Compare: binaries that use setuid-root (all-or-nothing privilege)"
run "find /usr/bin /usr/sbin -perm -4000 -type f 2>/dev/null | head -20"

echo; echo "## 6. A running service that runs with reduced privilege (if present)"
run "ps -eo user,pid,comm | grep -E 'systemd-(resolve|timesync|network)' | head -5"
for p in $(pgrep -x systemd-resolve 2>/dev/null | head -1); do
    run "grep -E '^(Uid|CapEff)' /proc/$p/status"
done
