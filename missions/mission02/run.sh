#!/usr/bin/env bash
# Mission 2: Meet the Kernel — syscall_demo.c traced with strace
# Run inside the lab VM:  bash missions/mission02/run.sh
# Output is saved to evidence/mission02/output.txt

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
OUT="$ROOT/evidence/mission02/output.txt"
WORKDIR="$(mktemp -d)"
mkdir -p "$(dirname "$OUT")"
exec > >(tee "$OUT") 2>&1

run() { echo; echo "\$ $*"; eval "$@"; }

echo "# Mission 2 run on $(hostname) at $(date -Is) as $(whoami)"

cd "$WORKDIR" || exit 1
echo; echo "## 1. Normal run"
run gcc -Wall -Wextra "$ROOT/missions/mission02/syscall_demo.c" -o syscall_demo
run ./syscall_demo
run cat hello.txt

echo; echo "## 2. Traced run (requires strace: apt install -y strace)"
rm -f hello.txt
run "strace ./syscall_demo 2>&1 | head -50"
