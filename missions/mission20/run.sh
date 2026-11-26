#!/usr/bin/env bash
# Mission 20: Secure Remote Access — install/verify local SSH.
# Run inside the lab VM:  bash missions/mission20/run.sh
# Output is saved to evidence/mission20/output.txt
#
# NOTE: `ssh localhost` itself needs an interactive password/host-key prompt,
# so it is not run by this script. After this script finishes, run it
# yourself in the same terminal and append the transcript to output.txt:
#   ssh localhost 'whoami; exit' 2>&1 | tee -a evidence/mission20/output.txt

OUT="$(cd "$(dirname "$0")/../.." && pwd)/evidence/mission20/output.txt"
mkdir -p "$(dirname "$OUT")"
exec > >(tee "$OUT") 2>&1

run() { echo; echo "\$ $*"; eval "$@"; }

echo "# Mission 20 run on $(hostname) at $(date -Is) as $(whoami)"

command -v sshd >/dev/null || run sudo apt install -y openssh-server
run sudo systemctl status ssh --no-pager
run "ss -lnt | grep ':22' || true"
run "sudo journalctl -u ssh --no-pager | tail -20"

echo
echo "# Now run interactively:  ssh localhost 'whoami; exit'"
echo "# and append its output to this file."
