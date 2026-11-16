# Protect Runner Runtime Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Prevent `remove_folders` from deleting the Node.js runtime required by subsequent GitHub Actions steps while preserving unrelated cleanup.

**Architecture:** Resolve cached runner `externals/node*` links before removal and filter any requested path that overlaps an active runtime. Apply one filtered path list to both the parallel `rm` and sequential `rmz` implementations, with isolated shell regression tests using temporary directories.

**Tech Stack:** Bash, GNU/BSD `realpath`, ShellCheck, GitHub Actions YAML.

**Spec:** `docs/superpowers/specs/2026-11-16-protect-runner-runtime-design.md`

## Global Constraints

- Add no dependencies; use Bash and utilities already available on Ubuntu runners.
- Preserve parallel `rm`, sequential `rmz`, and testing-mode behavior for unprotected paths.
- Emit a GitHub Actions warning for every protected path skipped.
- Do not protect `/opt/hostedtoolcache`, `/opt/actionarchivecache`, or unrelated runner-cache contents.
- Do not commit unless the maintainer explicitly requests a commit.

## Review Focus

- A requested parent such as `/opt/runner-cache` or `/opt` must not delete the resolved runtime; covered by Task 1 parent-path tests for `rm` and `rmz`.
- A requested path at or below the resolved runtime must also be skipped; covered by Task 1 nested-path tests.
- Installer archives and siblings inside `/opt/runner-cache` must remain removable; covered by Task 1 safe-sibling tests.
- Runners without matching cached Node paths must retain existing cleanup behavior; covered by Task 1 no-runtime-layout test.
- Testing mode must report skips without printing removal commands for protected paths; covered by Task 1 echo-output assertions.

---

### Task 1: Runtime Protection and Regression Tests

**Files:**
- Create: `tests/test_runner_runtime_protection.sh`
- Modify: `main.sh:328-353`

**Interfaces:**
- Consumes: `RUNNER_HOME` when set; otherwise `/home/runner/actions-runner`.
- Produces: `get_active_runner_runtime_paths()` printing canonical runtime paths; `is_active_runner_runtime_path(candidate)` returning `0` for an overlapping path and `1` otherwise; a filtered `remove_folders()` used by both removal modes.

- [ ] **Step 1: Write the failing isolated regression test**

Create a Bash harness that sources `main.sh` with all cleanup flags disabled, then overrides disk measurement and uses fake `sudo`/`rmz` commands confined to a temporary directory. Build a fake `RUNNER_HOME/cached/2.338.2/externals/node24` symlink targeting a temporary `opt/runner-cache/externals/node24` containing a marker file.

Add assertions for each Review Focus case: parent and nested runtime paths survive, unrelated paths and runner-cache siblings are removed, an empty cached-Node glob preserves existing behavior, and testing mode warns without emitting a protected removal. Exercise real temporary deletion with `RM_CMD=rm` and the fake `rmz` branch with `RM_CMD=rmz`.

- [ ] **Step 2: Run the test to verify the current implementation fails**

Run: `bash tests/test_runner_runtime_protection.sh`

Expected: FAIL because the current unfiltered removal deletes the runtime marker through the fake `/opt/runner-cache` parent.

- [ ] **Step 3: Implement runtime discovery and overlap checks**

Add `get_active_runner_runtime_paths()` to resolve existing `${RUNNER_HOME}/cached/*/externals/node*` entries with `realpath`. Add `is_active_runner_runtime_path(candidate)` to canonicalize the candidate and return protected when either canonical path contains the other.

- [ ] **Step 4: Filter both removal paths before deletion**

In `remove_folders()`, expand the existing space-separated input and globs once into a safe-path array. For each protected candidate, emit `::warning::Skipping <path>: it overlaps the active GitHub Actions Node.js runtime`; otherwise append it to the array. Feed the array to the existing parallel `rm` command and `rmz` loop, guarding empty input without changing unrelated removal behavior.

- [ ] **Step 5: Run regression and lint checks**

Run: `bash tests/test_runner_runtime_protection.sh`

Expected: PASS for both removal modes and all Review Focus cases.

Run: `shellcheck main.sh tests/test_runner_runtime_protection.sh -o all -e SC2033,SC2032`

Expected: PASS with no diagnostics.

### Task 2: CI and Documentation Alignment

**Files:**
- Modify: `.github/workflows/testing.yaml:27-38,136-149,199-213`
- Modify: `AGENTS.md:61`
- Modify: `README.md:221-235`

**Interfaces:**
- Consumes: the regression command from Task 1.
- Produces: CI execution of the regression test and documentation that distinguishes protected runtime data from safe cleanup candidates.

- [ ] **Step 1: Add the regression test to CI and remove unsafe workflow inputs**

Run `bash tests/test_runner_runtime_protection.sh` immediately after the existing ShellCheck step. Remove only `/opt/runner-cache` from the `test_full` and `test_large_removal` `remove_folders` values, leaving `/opt/actionarchivecache` and all other inputs unchanged.

- [ ] **Step 2: Correct maintainer and user documentation**

Replace the `/opt/runner-cache` cleanup candidate in `AGENTS.md` with the active-externals hazard and the new automatic protection. Add a short `remove_folders` note in `README.md` explaining that paths overlapping the active runner Node.js runtime are skipped with a warning.

- [ ] **Step 3: Validate the final deliverable locally**

Run: `bash tests/test_runner_runtime_protection.sh`

Run: `shellcheck main.sh tests/test_runner_runtime_protection.sh -o all -e SC2033,SC2032`

Run the documented `TESTING=true` invocation of `main.sh` with `RM_CMD=rm` and confirm successful completion. Inspect the workflow diff to verify that both unsafe inputs were removed and no unrelated test configuration changed.

Expected: all local checks pass. Hosted-runner integration remains subject to the normal GitHub Actions matrix after push or manual dispatch; do not claim that remote matrix passed without observing it.
