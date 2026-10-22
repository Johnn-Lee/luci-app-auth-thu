# Signed packages and reliable core updates

Goal: publish an independently signed APK, keep standard local IPK installation, and correct the reproduced credential, download and update bugs.

Implementation:
1. Keep one project ECDSA signing identity in the APK_SIGNING_KEY Actions secret. Commit only its public key. Sign APK artifacts with the SDK host apk, distribute the public key, and test rejection with no key / a wrong key / tampering, plus acceptance with the project key.
2. Bootstrap that specific public key in feed.sh after verifying its pinned SHA-256. Install with normal apk add. Document the one-time trust requirement and the distinct opkg index-signature model.
3. Replace interpolated shell source with constant shell source and quoted positional arguments in the procd command. Test literal credentials containing spaces, dollar signs, quotes and command substitutions.
4. Read current download form values. Move privileged download/validation/replacement into a narrow helper with write-only RPC permission; validate the ELF and version, check all command results, and rename from the destination filesystem so a failed download never truncates the installed core.
5. Increment the package version and document that every release needs a version/revision increase. Add regression tests and run them before both SDK builds.

Verification: Node behavior tests, shell regression tests, JSON/shell syntax checks, actual SDK builds and signature tests, isolated package-manager installation checks, git diff --check, and comparison of the pushed remote SHA. No physical router or campus network is available, so those runtime checks remain outside this validation.
