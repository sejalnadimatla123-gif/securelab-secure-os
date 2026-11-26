#!/usr/bin/env bash
# Mission 14: What Happened While I Was Away? — journald/login history
# Run inside the lab VM:  bash missions/mission14/run.sh
# Output is saved to evidence/mission14/output.txt

OUT="$(cd "$(dirname "$0")/../.." && pwd)/evidence/mission14/output.txt"
mkdir -p "$(dirname "$OUT")"
exec > >(tee "$OUT") 2>&1

run() { echo; echo "\$ $*"; eval "$@"; }

echo "# Mission 14 run on $(hostname) at $(date -Is) as $(whoami)"

run journalctl -n 30 --no-pager
run "journalctl --since '15 minutes ago' --no-pager"
run "sudo systemctl status ssh --no-pager 2>/dev/null || true"
run "journalctl -u ssh --no-pager 2>/dev/null | tail -30"
run "last | head -10"
