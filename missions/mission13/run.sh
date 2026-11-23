#!/usr/bin/env bash
# Mission 13: Can We Trust the File? — integrity with SHA-256
# Run inside the lab VM:  bash missions/mission13/run.sh
# Works in a scratch directory; output saved to evidence/mission13/output.txt

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
OUT="$ROOT/evidence/mission13/output.txt"
mkdir -p "$(dirname "$OUT")"
exec > >(tee "$OUT") 2>&1

run() { echo; echo "\$ $*"; eval "$@"; }

WORK="$(mktemp -d)"
cd "$WORK" || exit 1
echo "# Mission 13 run on $(hostname) at $(date -Is) as $(whoami) in $WORK"

echo; echo "## 1. Baseline hash of the approved file"
run "echo 'Approved configuration' > config.txt"
run "sha256sum config.txt > config.sha256"
run cat config.sha256
run sha256sum -c config.sha256

echo; echo "## 2. Modify the file and re-check"
run "echo 'Unexpected change' >> config.txt"
run sha256sum config.txt
run "sha256sum -c config.sha256 || echo \"[exit \$?] INTEGRITY CHECK FAILED\""

echo; echo "## 3. Avalanche effect: a 1-character change gives a completely different hash"
run "echo 'Approved configuration' | sha256sum"
run "echo 'approved configuration' | sha256sum"

echo; echo "## 4. Hash != authenticity: attacker modifies the file AND regenerates the hash"
run "echo 'Approved configuration' > config.txt && sha256sum config.txt > config.sha256"
run "echo 'malicious_setting=on' >> config.txt"
run "sha256sum config.txt > config.sha256   # attacker can write the .sha256 too"
run sha256sum -c config.sha256
echo "=> Check PASSES even though the file was tampered with: the hash only proves"
echo "   'unchanged since the hash was made', not WHO made it."

echo; echo "## 5. Keyed hash (HMAC): without the secret key the attacker cannot forge the tag"
KEY="lab-secret-key"
run "echo 'Approved configuration' > config.txt"
run "openssl dgst -sha256 -hmac '$KEY' config.txt | tee config.hmac"
run "echo 'malicious_setting=on' >> config.txt"
run "openssl dgst -sha256 -hmac 'attacker-guess' config.txt   # attacker's forged tag"
run "openssl dgst -sha256 -hmac '$KEY' config.txt             # verifier recomputes with real key"
run "diff <(openssl dgst -sha256 -hmac '$KEY' config.txt) config.hmac && echo AUTHENTIC || echo '[mismatch] TAMPERING DETECTED'"

cd / && rm -rf "$WORK"
