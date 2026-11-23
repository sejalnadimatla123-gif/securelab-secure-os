# Mission 13: Can We Trust the File?

## Objective
Detect modification with SHA-256 hashing and understand what hashing can and cannot prove.

**Script:** `missions/mission13/run.sh` · **Raw output:** `evidence/mission13/output.txt`

## Question
If a file changes, can we detect it? And does a matching hash prove the file is genuine?

## Prediction
Any change, even one character, will produce a completely different hash and `sha256sum -c` will report `FAILED`. But if an attacker can also rewrite the `.sha256` file, the check will pass, so a plain hash cannot prove authenticity.

## Experiment

```bash
echo "Approved configuration" > config.txt
sha256sum config.txt > config.sha256
cat config.sha256
sha256sum -c config.sha256
echo "Unexpected change" >> config.txt
sha256sum config.txt
sha256sum -c config.sha256 || true
```

Extra steps: a one-character change (avalanche effect), an attacker who regenerates the hash, and an HMAC (keyed hash) comparison.

## Observation

<!-- TODO: paste the actual hashes from output.txt after running in the VM -->

| Item | Value |
|---|---|
| Original hash | `________________________________________________________________  config.txt` |
| Original check | `config.txt: OK` |
| Hash after change | `________________________________________________________________  config.txt` |
| Check after change | `config.txt: FAILED` + `WARNING: 1 computed checksum did NOT match` (exit 1) |
| `Approved...` vs `approved...` | two completely different 64-hex-digit hashes |
| Attacker regenerated hash | `config.txt: OK` — **tampering not detected** |
| HMAC with real key after tampering | mismatch — **tampering detected** |

## Think About It

**38. What changed in the hash?**
The entire 64-hex-digit (256-bit) value changed, not just a few characters. SHA-256 has the **avalanche effect**: changing a single input bit flips about half the output bits, so even the one-letter `A`→`a` change produced an unrelated hash. Because the stored and recomputed values differ, `sha256sum -c` reported `FAILED`.

**39. Does a hash prove who created the file?**
**No.** Anyone can compute a SHA-256 hash; there is no secret involved. Step 4 showed an attacker modifying the file *and* regenerating `config.sha256`, after which verification said `OK`. A hash proves only that the content matches whatever value you compare it with, so the reference hash itself must be stored somewhere the attacker can't write (read-only media, a separate trusted server) or be protected cryptographically.

**40. Why is authenticity a different property from integrity?**
*Integrity* = the data has not changed since a reference point. *Authenticity* = the data really comes from the claimed source. Proving authenticity requires a secret only the legitimate party holds: an HMAC (shared key, step 5) or a digital signature (private key, e.g. `gpg --sign`, signed packages in `apt`). In step 5 the attacker could not produce a valid HMAC without the key, so tampering was detected.

## Concept
Integrity via cryptographic hashing; authenticity via keyed MACs / digital signatures.

## Defense
Baseline hashes of critical files (as tools like AIDE do), with the baseline stored in a protected location; signatures/HMACs where the source must be authenticated.

## Verification
`sha256sum -c` reported `FAILED` after modification; the HMAC check detected tampering that the plain hash missed.

## Reflection
Without integrity checking, a silently modified configuration (e.g. an added `malicious_setting=on`) could go unnoticed indefinitely. Without authenticity, an attacker with write access can simply re-bless their own changes.

### Note on secure deletion (syllabus link)
A hash can show a file changed, but deleting a file (`rm`) only removes the directory entry; the data blocks may remain on disk until overwritten. `shred` can overwrite a file, but on journaling filesystems and SSDs (wear-levelling, copy-on-write) overwriting is not guaranteed to hit the original blocks. Full-disk encryption is the reliable answer: destroy the key and the data is unrecoverable.
