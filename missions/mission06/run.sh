#!/usr/bin/env bash
# Mission 6: Two Processes Need to Talk — pipe-based IPC
# Run:  bash missions/mission06/run.sh
# Output is saved to evidence/mission06/output.txt

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
OUT="$ROOT/evidence/mission06/output.txt"
mkdir -p "$(dirname "$OUT")"
exec > >(tee "$OUT") 2>&1

run() { echo; echo "\$ $*"; eval "$@"; }

echo "# Mission 6 run on $(hostname) at $(date -Is 2>/dev/null || date) as $(whoami)"

run gcc -Wall -Wextra "$ROOT/missions/mission06/pipe_ipc.c" -o /tmp/pipe_ipc
run /tmp/pipe_ipc
