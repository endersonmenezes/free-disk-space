# Active Swap Files Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make `remove_swap` discover, disable, and delete every active file-based swap so Ubuntu 24.04's `/swapfile` is reclaimed.

**Architecture:** A small helper reads `/proc/swaps` and emits only paths whose type is `file`. `remove_swap_storage` captures that list, disables each file individually, and removes it through the existing `run_rm` wrapper only when `swapoff` succeeds.

**Tech Stack:** Bash, Linux `/proc/swaps`, existing shell regression-test harnesses, GitHub Actions.

**Spec:** `docs/superpowers/specs/2026-11-23-active-swap-files-design.md`

## Global Constraints

- Preserve swap partitions and files whose `swapoff` fails.
- Do not remove inactive swap files or add an action input.
- Support both `rm` and `rmz` without new dependencies.
- Follow the existing Bash conventions and pass `shellcheck main.sh -o all -e SC2033,SC2032`.

## Review Focus

- Multiple active files: every file is disabled and removed, not just the first or a hard-coded path.
- Non-file swap: partition entries such as `/dev/zram0` are neither disabled nor removed.
- Failed disable: a file remains on disk and a warning identifies it.
- Header-only or missing file data: no removal command is attempted.
- Removal backends: both `rm` and `rmz` receive each discovered path unchanged.

---

### Task 1: Discover and remove active swap files

**Files:**
- Modify: `main.sh:356-366`
- Create: `tests/test_active_swap_files.sh`
- Modify: `.github/workflows/testing.yaml:40-47`
- Modify: `README.md:49`
- Modify: `CHANGELOG.md` (Unreleased)

**Interfaces:**
- Produces: `get_active_swap_files [PROC_SWAPS_FILE]`, printing one active file path per line; the optional argument defaults to `/proc/swaps` and exists for fixture-based tests.
- Consumes: existing `run_rm -f PATH`, which supports `rm`, `rmz`, and testing mode.
- Updates: `remove_swap_storage` takes no arguments and passes `${PROC_SWAPS_FILE:-/proc/swaps}` to `get_active_swap_files`; the internal environment override supports end-to-end fixtures without adding an action input.

- [ ] **Step 1: Write the failing regression test**

Create a self-contained Bash harness that sources `main.sh` with all cleanup flags disabled, uses temporary fixture files and fake `bc`/`sudo` executables, and neutralizes disk and memory measurements. Pin these assertions:

- A fixture containing `/swapfile` and `/mnt/swapfile` as `file` entries causes both temporary backing files to be removed.
- A `/dev/zram0` entry of type `partition` is not passed to `swapoff` or removed.
- When fake `swapoff` fails for `/swapfile`, that file remains and the output contains a warning naming the path.
- A header-only fixture produces no `swapoff` or removal calls.
- The discovery and successful-removal case passes with both `RM_CMD=rm` and `RM_CMD=rmz`.
- `/swapfile` is used literally in at least one fixture; no assumption of `/mnt/swapfile` remains.

- [ ] **Step 2: Run the test to verify it fails**

Run: `bash tests/test_active_swap_files.sh`

Expected: FAIL because `get_active_swap_files` is undefined and the current implementation removes only `/mnt/swapfile` after `swapoff -a`.

- [ ] **Step 3: Implement discovery and guarded removal**

Add `get_active_swap_files [PROC_SWAPS_FILE]` beside `remove_swap_storage`. Read data rows from the supplied file, select only rows whose second column is `file`, and print the first column.

Change `remove_swap_storage` to call the helper with `${PROC_SWAPS_FILE:-/proc/swaps}` and capture the full discovered list before running `swapoff`. For each nonempty path, run `sudo swapoff "PATH"`; on success call `run_rm -f "PATH" || true`, and on failure emit `::warning::Could not disable swap file PATH; leaving it in place`. Preserve the existing `free -h` output before and after the operation.

- [ ] **Step 4: Wire documentation and CI**

Add `bash tests/test_active_swap_files.sh` to the existing ShellCheck job. Change the `remove_swap` README description to say it disables and removes active swap files. Add an Unreleased fixed entry explaining that active swap files are discovered rather than assuming `/mnt/swapfile`.

- [ ] **Step 5: Run focused and existing regression tests**

Run:

```bash
bash tests/test_active_swap_files.sh
bash tests/test_runner_runtime_protection.sh
bash tests/test_temporary_bc.sh
bash tests/test_rmz_checksum.sh
```

Expected: all four commands exit 0; the new test covers every assertion in Step 1.

- [ ] **Step 6: Run static and end-to-end validation**

Run:

```bash
shellcheck main.sh -o all -e SC2033,SC2032
shellcheck tests/test_active_swap_files.sh -o all -e SC2033,SC2032
```

Then run `main.sh` with the repository's documented local testing environment, `SWAP_STORAGE=true`, `PROC_SWAPS_FILE` pointing to a `/swapfile` fixture, and fake `sudo`/`free` commands confined to a temporary directory so no real swap is changed. Expected: ShellCheck passes, `/swapfile` is discovered and echoed for removal, and the script exits 0.

- [ ] **Step 7: Review the final diff and commit**

Check `git diff --check`, `git status --short`, and the complete diff. Confirm there are no generated files or unrelated changes, then commit all design, implementation, test, CI, and documentation files with:

```bash
git commit -m "fix(action): remove active swap files"
```
