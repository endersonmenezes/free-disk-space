# Verify rmz Checksums Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Verify every downloaded `rmz` binary with SHA-256 before privileged installation while preserving existing action inputs and defaults.

**Architecture:** Resolve an explicit or pinned checksum after architecture selection, validate it before download, and gate `sudo install` on `sha256sum -c`. An isolated subprocess harness uses command doubles to prove which binaries would be downloaded and installed without executing or installing `rmz`.

**Tech Stack:** Bash, GNU `sha256sum`, ShellCheck, GitHub Actions composite YAML.

**Spec:** `docs/superpowers/specs/2026-11-20-verify-rmz-checksums-design.md`

## Global Constraints

- Preserve all existing input names and defaults; add only optional `rmz_sha256` with default `""`.
- Pin `3.2.0` x86_64 to `7dc19b56caeab9611b578355bbc58c791d1830177651817dec339e0e926286ce` and aarch64 to `49f6aaddf00ac3e4ae2a7928d1d651ea708b0bedd577a94d08ece44414cf3a36`.
- Never call `sudo install` before successful checksum verification.
- Use graceful `exit 0` for expected validation and download failures, consistently with `main.sh`.
- Add no dependencies and keep `RM_CMD=rm` unchanged.

## Review Focus

- A replaced pinned asset must not be installed; Task 1 mismatch tests assert an empty sudo log.
- An unpinned version without a valid checksum must fail before network access; Task 1 missing/malformed tests assert an empty curl log.
- x86_64 and aarch64 must use different pins; Task 1 architecture tests assert exact hashes and asset URLs.
- Existing default configurations must not require `RMZ_SHA256`; Task 1 pinned-default and `rm` tests cover both paths.
- Explicit checksums must remain available for custom versions; Task 1 custom-version and override tests cover them.

---

### Task 1: Checksum Enforcement and Regression Tests

**Files:**
- Create: `tests/test_rmz_checksum.sh`
- Modify: `main.sh:21-23,86-95,128-156`

**Interfaces:**
- Consumes: existing `RM_CMD`, `RMZ_VERSION`, and new optional `RMZ_SHA256` environment variables.
- Produces: verified temporary `rmz` asset installation; no other function signatures change.

- [ ] **Step 1: Write the failing isolated regression test**

Create a Bash harness that runs `main.sh` in subprocesses with all cleanup flags disabled and temporary PATH doubles. Record curl, sudo, and checksum invocations. Assert successful pinned x86_64 and aarch64 flows, rejected mismatch, missing and malformed custom checksums, a valid custom `9.9.9` flow, explicit override of a pinned hash, and no rmz setup for `RM_CMD=rm`.

- [ ] **Step 2: Run the test to verify the current implementation fails**

Run: `bash tests/test_rmz_checksum.sh`

Expected: FAIL because the current script installs without invoking `sha256sum` and accepts an unpinned version without `RMZ_SHA256`.

- [ ] **Step 3: Implement checksum selection, validation, and enforcement**

Document `RMZ_SHA256` in the variable header. After asset selection, prefer a nonempty explicit checksum, otherwise select the exact pin for the version and asset. Validate 64 hexadecimal characters and reject an unpinned version without a checksum before curl. Gate installation on `printf '%s  %s\n' "$expected" "$tmpfile" | sha256sum -c -`; remove the temporary file and exit gracefully on failure.

- [ ] **Step 4: Run regression and lint checks**

Run: `bash tests/test_rmz_checksum.sh`

Expected: PASS for every Review Focus case.

Run: `shellcheck main.sh tests/test_rmz_checksum.sh -o all -e SC2033,SC2032`

Expected: PASS with no diagnostics.

### Task 2: Action Wiring, CI, and Documentation

**Files:**
- Modify: `action.yaml:50-53,88-90`
- Modify: `.github/workflows/testing.yaml:37-41`
- Modify: `README.md`
- Modify: `AGENTS.md`
- Modify: `.github/copilot-instructions.md`
- Modify: `CHANGELOG.md`

**Interfaces:**
- Consumes: `RMZ_SHA256` and `bash tests/test_rmz_checksum.sh` from Task 1.
- Produces: optional `rmz_sha256` action input, CI regression coverage, and English documentation of default and custom checksum behavior.

- [ ] **Step 1: Wire the optional input and regression test**

Add `rmz_sha256` with `required: false` and `default: ""`, map it to `RMZ_SHA256`, and run the new regression test immediately after the existing runner-runtime regression in the ShellCheck job. Do not alter existing inputs or the test matrix.

- [ ] **Step 2: Update user and maintainer documentation**

Add the input to the README and maintainer tables. Explain that 3.2.0 is pinned on both architectures and other versions require a 64-character SHA-256. Add checksum mismatch/missing-checksum troubleshooting and an Unreleased changelog entry.

- [ ] **Step 3: Validate the final deliverable locally**

Run both regression suites and ShellCheck across `main.sh` and both test scripts. Run the documented `TESTING=true` invocation with `RM_CMD=rm`. Parse `action.yaml` and workflow YAML with the repository's available validation tools and inspect the complete diff for schema compatibility.

Expected: all local checks pass. The hosted-runner matrix and manual approval remain required before merge.

- [ ] **Step 4: Commit and open a draft PR**

Commit with `fix(action): verify rmz download checksums`. Open a draft PR linked to issue #32 that identifies the work as automated, lists local and pending hosted checks, and explicitly requests manual review and approval before merge.
