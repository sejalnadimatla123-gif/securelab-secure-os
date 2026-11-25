#!/usr/bin/env bash
# Mission 11: Why Didn't the Attack Work? — checksec + ASLR + stack permissions
# Run inside the lab VM:  bash missions/mission11/run.sh
# Output is saved to evidence/mission11/output.txt

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
OUT="$ROOT/evidence/mission11/output.txt"
mkdir -p "$(dirname "$OUT")"
exec > >(tee "$OUT") 2>&1

run() { echo; echo "\$ $*"; eval "$@"; }

echo "# Mission 11 run on $(hostname) at $(date -Is) as $(whoami)"

command -v checksec >/dev/null || sudo apt install -y checksec

run gcc -Wall -Wextra -O0 -fstack-protector-strong -fPIE -pie \
    "$ROOT/missions/mission10/memory_overflow_demo.c" -o /tmp/memory_protected

run checksec --file=/tmp/memory_protected
run cat /proc/sys/kernel/randomize_va_space
run "readelf -W -l /tmp/memory_protected | grep GNU_STACK"
