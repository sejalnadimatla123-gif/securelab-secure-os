#!/usr/bin/env bash
# Mission 10: The Dangerous Array — observe an unchecked memcpy overflow.
# Run inside the lab VM:  bash missions/mission10/run.sh
# Output is saved to evidence/mission10/output.txt

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
OUT="$ROOT/evidence/mission10/output.txt"
mkdir -p "$(dirname "$OUT")"
exec > >(tee "$OUT") 2>&1

run() { echo; echo "\$ $*"; eval "$@"; }

echo "# Mission 10 run on $(hostname) at $(date -Is) as $(whoami)"

run gcc -Wall -Wextra -O0 -g "$ROOT/missions/mission10/memory_overflow_demo.c" -o /tmp/memory_overflow_demo
run /tmp/memory_overflow_demo
