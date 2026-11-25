#!/usr/bin/env bash
# Mission 22: FINAL CHALLENGE — baseline collection.
# Run this FIRST, before touching any configuration, against the
# instructor-provided target (OVA import / public vulnerable VM / snapshot).
#
#   bash final_assessment/baseline.sh
#
# Output is saved to final_assessment/baseline_<timestamp>.txt so repeated
# runs (before/after a fix) don't overwrite each other.

OUT="final_assessment/baseline_$(date +%Y%m%d_%H%M%S).txt"
mkdir -p final_assessment
exec > >(tee "$OUT") 2>&1

run() { echo; echo "\$ $*"; eval "$@" 2>&1; }

echo "# Mission 22 baseline on $(hostname) at $(date -Is 2>/dev/null || date) as $(whoami)"

echo; echo "## Users"
run cat /etc/passwd
run "awk -F: '(\$3==0){print}' /etc/passwd   # other UID-0 accounts besides root"
run lastlog 2>/dev/null

echo; echo "## Processes"
run "ps -eo pid,ppid,user,uid,euid,%cpu,%mem,cmd --sort=-%cpu | head -30"

echo; echo "## Services"
run "systemctl --type=service --state=running --no-pager"

echo; echo "## Listening network sockets"
run "ss -lntup"
run "sudo ufw status verbose 2>/dev/null || true"

echo; echo "## Kernel / patch level"
run uname -a
run "apt list --upgradable 2>/dev/null | head -30"

echo; echo "## Interesting files: world-writable, SUID/SGID, no-owner"
run "find / -xdev -type f -perm -0002 2>/dev/null | head -30"
run "find / -xdev -perm -4000 -o -perm -2000 2>/dev/null | head -30"
run "find / -xdev -nouser -o -nogroup 2>/dev/null | head -30"

echo; echo "## AppArmor / MAC status"
run "sudo aa-status 2>/dev/null || true"

echo; echo "## Sudo configuration"
run "sudo -l 2>/dev/null || true"
run "cat /etc/sudoers.d/* 2>/dev/null"

echo; echo "## Logging"
run "journalctl -n 20 --no-pager 2>/dev/null || true"
run "last | head -10"
