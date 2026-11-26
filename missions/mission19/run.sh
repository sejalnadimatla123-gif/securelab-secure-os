#!/usr/bin/env bash
# Mission 19: Harden the Machine — verification re-check.
# The hardening changes themselves (UFW, sysctl, sshd_config) are already
# documented and applied per evidence/mission19/results.md. This script is
# READ-ONLY: it re-verifies the current state, it does not re-apply changes.
# Run inside the lab VM:  bash missions/mission19/run.sh
# Output is saved to evidence/mission19/output.txt

OUT="$(cd "$(dirname "$0")/../.." && pwd)/evidence/mission19/output.txt"
mkdir -p "$(dirname "$OUT")"
exec > >(tee "$OUT") 2>&1

run() { echo; echo "\$ $*"; eval "$@"; }

echo "# Mission 19 verification run on $(hostname) at $(date -Is) as $(whoami)"

echo; echo "## Baseline-style snapshot"
run "apt list --upgradable 2>/dev/null | wc -l"
run "systemctl --type=service --state=running --no-pager | wc -l"
run "ss -lntup 2>/dev/null | wc -l"
run uname -r

echo; echo "## Verify applied hardening (read-only)"
run sudo ufw status verbose
run "sysctl net.ipv4.conf.all.accept_redirects net.ipv4.conf.default.accept_redirects net.ipv4.conf.all.send_redirects"
run "sudo sshd -T | grep -E 'permitrootlogin|maxauthtries'"
run sudo systemctl is-active ssh
run sudo systemctl is-enabled ssh
