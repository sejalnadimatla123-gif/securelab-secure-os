#!/usr/bin/env bash
# Mission 16: Build Your First Container Sandbox — namespace/cgroup isolation via Docker
# Run inside the lab VM (after installing Docker per official docs):
#   bash missions/mission16/run.sh
# Output is saved to evidence/mission16/output.txt

OUT="$(cd "$(dirname "$0")/../.." && pwd)/evidence/mission16/output.txt"
mkdir -p "$(dirname "$OUT")"
exec > >(tee "$OUT") 2>&1

run() { echo; echo "\$ $*"; eval "$@"; }

echo "# Mission 16 run on $(hostname) at $(date -Is) as $(whoami)"

run docker run --rm hello-world
run docker run --rm ubuntu:26.04 uname -a
run docker run --rm ubuntu:26.04 cat /etc/os-release
run docker run --rm ubuntu:26.04 ps
