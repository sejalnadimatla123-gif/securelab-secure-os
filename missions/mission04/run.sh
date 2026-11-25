#!/usr/bin/env bash
# Mission 4: Can One Process Read Another? — address_space.c + /proc/<PID>/maps
# Run inside the lab VM:  bash missions/mission04/run.sh
# Output is saved to evidence/mission04/output.txt

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
OUT="$ROOT/evidence/mission04/output.txt"
mkdir -p "$(dirname "$OUT")"
exec > >(tee "$OUT") 2>&1

run() { echo; echo "\$ $*"; eval "$@"; }

echo "# Mission 4 run on $(hostname) at $(date -Is) as $(whoami)"

run gcc -Wall -Wextra "$ROOT/missions/mission04/address_space.c" -o /tmp/address_space

echo; echo "## 1. Launch in the background, capture its PID and printed pointer"
/tmp/address_space > /tmp/address_space.out &
PID=$!
sleep 1
cat /tmp/address_space.out

echo; echo "## 2. From this script (acting as the 'second terminal'), inspect its memory map"
run "cat /proc/$PID/maps"

wait "$PID"
