#!/usr/bin/env bash
# Mission 17: Linux Says No — AppArmor status and loaded profiles
# Run inside the lab VM:  bash missions/mission17/run.sh
# Output is saved to evidence/mission17/output.txt

OUT="$(cd "$(dirname "$0")/../.." && pwd)/evidence/mission17/output.txt"
mkdir -p "$(dirname "$OUT")"
exec > >(tee "$OUT") 2>&1

run() { echo; echo "\$ $*"; eval "$@"; }

echo "# Mission 17 run on $(hostname) at $(date -Is) as $(whoami)"

command -v aa-status >/dev/null || sudo apt install -y apparmor apparmor-utils
run sudo aa-status
run "sudo aa-unconfined 2>/dev/null | head -20"
