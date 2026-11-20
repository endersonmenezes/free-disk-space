# Verify rmz Download Checksums

## Intent

Close issue #32 by ensuring the action never installs a downloaded `rmz` binary with `sudo` until its SHA-256 checksum has been verified.

## Goals

- Pin the SHA-256 of both supported Linux `rmz` 3.2.0 assets.
- Preserve the existing `rm_cmd: rmz` and `rmz_version: 3.2.0` behavior without requiring new inputs.
- Add optional `rmz_sha256` for explicit verification of other versions or an intentional override of a pinned checksum.
- Refuse missing, malformed, or mismatching checksums before installation.
- Keep the default `rm_cmd: rm` path unchanged.

## Non-goals

- Do not remove or rename existing inputs or change their defaults.
- Do not add signature infrastructure, dependencies, or support for new architectures.
- Do not execute downloaded binaries during checksum verification.

## Constraints

- Use Bash and `sha256sum`, already available on supported Ubuntu runners.
- Follow the project's graceful `exit 0` validation behavior while skipping installation and cleanup after a failure.
- Keep all issue, PR, and user-facing repository documentation in English.

## Approaches

1. **Allow unverified custom versions.** Rejected: it leaves the reported privileged-execution path open.
2. **Support only pinned versions.** Rejected: unnecessarily removes the existing `rmz_version` flexibility.
3. **Pinned defaults plus explicit custom checksums.** Selected in the issue discussion. Known assets work transparently; every other download requires `rmz_sha256`, and every download is checked.

## Design

Add `rmz_sha256` as an optional action input mapped to `RMZ_SHA256`, with an empty default. During `rmz` setup, select the asset from `uname -m` as today. Use the supplied checksum when present; otherwise look up the pinned checksum for `3.2.0` and the selected x86_64 or aarch64 asset. Require exactly 64 hexadecimal characters. An unpinned version without a checksum fails before download.

Download to the existing temporary file, verify it with `sha256sum -c`, delete the temporary file and stop on mismatch, and invoke `sudo install` only after successful verification. The two pinned hashes were confirmed both through the GitHub release asset metadata and direct downloads.

Add an isolated subprocess regression harness with fake `curl`, `sudo`, `sha256sum`, `uname`, `bc`, and `rmz` commands. Cover both pinned architectures, custom versions, missing and malformed checksums, mismatches, explicit overrides, and the unaffected `rm` path. Wire the harness into the ShellCheck CI job and document the new input and failure behavior.

## Verification

- Run the new regression test before implementation and confirm the current installer performs no checksum verification.
- Run both local shell regression suites and ShellCheck on `main.sh` and the tests.
- Exercise `main.sh` in testing mode with `RM_CMD=rm`.
- Let the existing hosted-runner matrix exercise real `rmz` downloads on x86_64 and ARM64; require manual review of those results before merge.
