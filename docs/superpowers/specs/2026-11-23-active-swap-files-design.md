# Active swap file discovery design

## Intent

Resolve #34 by deleting the backing files of active file-based swap, including Ubuntu 24.04's `/swapfile`, instead of assuming only `/mnt/swapfile`.

## Goals and constraints

- Discover every active swap file and remove its backing file after successfully disabling it.
- Preserve swap partitions and files whose `swapoff` fails.
- Keep the existing Bash implementation and support both `rm` and `rmz` without new dependencies.
- Do not remove inactive swap files or add a new action input.

## Approaches

- **Read `/proc/swaps` (selected):** the kernel exposes active paths and types directly, with no additional command dependency. A helper will select only entries whose type is `file`.
- **Parse `swapon --show`:** provides equivalent data, but adds dependency and output-format concerns.
- **Add `/swapfile` as another fixed path:** smaller, but does not provide the generic discovery requested by the issue.

## Implementation

`remove_swap_storage` will capture active file paths before disabling swap, run `swapoff` for each path, and invoke `run_rm` only after a successful disable. A failed `swapoff` will emit a warning and preserve that file. The existing before/after `free -h` output remains. Tests may override the proc fixture through the internal `PROC_SWAPS_FILE` environment variable; production defaults to `/proc/swaps` and no action input is added.

A regression test will use fixture data and temporary files to cover `/swapfile`, multiple swap files, partition exclusion, failed `swapoff`, no active file-based swap, and both removal backends. The test will run in the existing ShellCheck CI job. User documentation and the unreleased changelog entry will describe active swap-file discovery.

## Verification

Run the new regression test, all existing regression tests, the configured ShellCheck command, and an end-to-end `main.sh` testing-mode invocation. Open a focused pull request with `Fixes #34`.
