#!/usr/bin/env bash
# Mission 15: The Suspicious Application — inspect a process's resources.
# Usage: bash missions/mission15/run.sh <PID>
# Output is saved to evidence/mission15/output.txt

PID="$1"
if [ -z "$PID" ]; then
    echo "Usage: $0 <PID>   (pick a PID you own, e.g. a GUI app's pid from ps)"
    exit 1
fi

OUT="$(cd "$(dirname "$0")/../.." && pwd)/evidence/mission15/output.txt"
mkdir -p "$(dirname "$OUT")"
exec > >(tee "$OUT") 2>&1

run() { echo; echo "\$ $*"; eval "$@"; }

echo "# Mission 15 run on $(hostname) at $(date -Is 2>/dev/null || date) as $(whoami)"

run "ps -p $PID -o pid,ppid,uid,euid,nlwp,%cpu,%mem,cmd"
run "ls -l /proc/$PID/fd"
run "cat /proc/$PID/status | grep -E 'Name|Uid|Gid|Threads'"
run ss -lntup
