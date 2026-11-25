#!/usr/bin/env bash
# Mission 1: Who Are You? — identity.c vs `id`
# Run inside the lab VM:  bash missions/mission01/run.sh
# Output is saved to evidence/mission01/output.txt

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
OUT="$ROOT/evidence/mission01/output.txt"
mkdir -p "$(dirname "$OUT")"
exec > >(tee "$OUT") 2>&1

run() { echo; echo "\$ $*"; eval "$@"; }

echo "# Mission 1 run on $(hostname) at $(date -Is) as $(whoami)"

echo; echo "## 1. Shell identity"
run whoami
run id
run groups

echo; echo "## 2. Process identity (compiled program)"
run gcc "$ROOT/missions/mission01/identity.c" -o /tmp/identity
run /tmp/identity

echo; echo "## 3. Network identity, for the attack-surface question"
run ip a 2>/dev/null || run ifconfig
