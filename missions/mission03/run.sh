#!/usr/bin/env bash
# Mission 3: Process Detective — run proc_inspector.sh against a process we own.
# Run inside the lab VM:  bash missions/mission03/run.sh
# Output is saved to evidence/mission03/output.txt

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
SCRIPT="$ROOT/missions/mission03/proc_inspector.sh"
OUT="$ROOT/evidence/mission03/output.txt"
mkdir -p "$(dirname "$OUT")"
exec > >(tee "$OUT") 2>&1
chmod +x "$SCRIPT"

run() { echo; echo "\$ $*"; eval "$@"; }

echo "# Mission 3 run on $(hostname) at $(date -Is) as $(whoami)"

echo; echo "## 1. Start a background process we own (sleep), inspect it"
sleep 120 &
PID=$!
run "$SCRIPT $PID"

echo; echo "## 2. Usage error (no PID given)"
run "$SCRIPT"

echo; echo "## 3. A process that does not exist"
run "$SCRIPT 999999"

kill "$PID" 2>/dev/null
