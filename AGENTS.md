# AGENTS.md — Free Disk Space Action

Deep technical reference for contributors and AI agents. For coding conventions, standards, and project overview, see [`.github/copilot-instructions.md`](.github/copilot-instructions.md). For user-facing documentation, see [README.md](README.md).

## AI Customization Files

| File | Purpose |
|------|---------|
| `.github/copilot-instructions.md` | Project conventions, coding standards, testing strategy (always loaded) |
| `.github/agents/disk-space-engineer.agent.md` | Custom agent: workflows, behavioral rules, task feedback |
| `.github/skills/changelog-maintainer/SKILL.md` | Skill for maintaining changelog entries |
| `.github/skills/release-manager/SKILL.md` | Skill for creating releases and updating major version alias tag |

> **Note**: `copilot-instructions.md` is the canonical source for code conventions, function patterns, ShellCheck, commit messages, testing matrix, and versioning. This file contains only supplementary technical details not covered there.

## Input → Environment Variable Mapping

| Input (`action.yaml`) | Env Var (`main.sh`) |
|------------------------|---------------------|
| `principal_dir` | `PRINCIPAL_DIR` |
| `remove_android` | `ANDROID_FILES` |
| `remove_dotnet` | `DOTNET_FILES` |
| `remove_haskell` | `HASKELL_FILES` |
| `remove_tool_cache` | `TOOL_CACHE` |
| `remove_swap` | `SWAP_STORAGE` |
| `remove_packages` | `PACKAGES` |
| `remove_packages_one_command` | `REMOVE_ONE_COMMAND` |
| `remove_folders` | `REMOVE_FOLDERS` |
| `rm_cmd` | `RM_CMD` |
| `rmz_version` | `RMZ_VERSION` |
| `testing` | `TESTING` |

System-provided: `AGENT_TOOLSDIRECTORY`, `GITHUB_REF`

## Runner Image Differences

Measured by the `search_biggest` CI job and the test dashboard (August 2026):

| Aspect | x86_64 (22.04 / 24.04 / latest) | ARM64 (22.04 / 24.04) | `ubuntu-26.04` (preview) | `ubuntu-26.04-arm` (preview) |
|--------|--------------------------------|------------------------|--------------------------|------------------------------|
| Initial free disk | ~87-88 GB | ~109 GB | ~94 GB | ~114 GB |
| Android SDK | Present (~11 GB) | Absent | Present (~11 GB) | Absent |
| .NET (`/usr/share/dotnet`) | Present | Present (~4 GB) | Present (~5 GB) | Present (~6 GB) |
| Haskell (`/usr/local/.ghcup`) | Present | Absent | Present (~4 GB) | Absent |
| Swift (`/usr/share/swift`) | Present | Present | Removed from image | Removed from image |

Notes on the 26.04 preview images:

- Toolchain bumps: LLVM 20/21/22 (was 16-18), Temurin 11/17/21/**25**, gcc 13/14/15 side by side, Python 3.14, kernel 7.0 (`linux-azure`).
- New large items: `/opt/runner-cache` (~1.1 GB), CodeQL inside the tool cache (~1.7 GB).
- Azure CLI is split across three locations: `azure-cli` package, `/opt/az` and `/usr/share/az_*`.
- The preview apt archive (`azure.archive.ubuntu.com/ubuntu resolute`) has been observed stalling mid-download; the `apt_get` wrapper bounds this with a 600s timeout.

Tests MUST pass on all architectures. The 26.04 runners run with `continue-on-error` (`experimental`) until they reach GA. Some cleanup functions are no-ops where the software is absent (e.g. Android/Haskell on ARM64, Swift on 26.04).

## Test Categories

- **Quick tests** (PR): `quick_test_dotnet`, `quick_test_android`, `quick_test_packages`, `quick_test_testing_mode`
- **Feature tests** (push): `test_basic`, `test_full`, `test_haskell`, `test_tool_cache_swap`
- **Package tests**: `test_packages_one_command`, `test_packages_individual`
- **Folder tests**: `test_folders`, `test_folder_swift`, `test_folder_hostedtoolcache`, etc.
- **Use-case tests**: `test_usecase_docker`, `test_usecase_python_ml`, `test_usecase_nodejs`, `test_usecase_java`

## Local Testing

```bash
export TESTING=true PRINCIPAL_DIR=/ ANDROID_FILES=true DOTNET_FILES=false \
  HASKELL_FILES=false TOOL_CACHE=false SWAP_STORAGE=false PACKAGES=false \
  REMOVE_ONE_COMMAND=false REMOVE_FOLDERS=false RM_CMD=rm RMZ_VERSION=3.2.0 \
  AGENT_TOOLSDIRECTORY=/usr/local/bin
bash main.sh
```

## Troubleshooting

| Issue | Cause | Solution |
|-------|-------|---------|
| "bc is not installed" | `bc` removed by `apt-get` | Script copies `bc` to `./bc` before cleanup — handled automatically |
| rmz installation fails | Network or unsupported arch | Script exits gracefully (`exit 0`), user can fall back to `rm` |
| Package removal hangs | Interactive debconf prompt or stalled archive download | Handled since v4: `DEBIAN_FRONTEND=noninteractive`, stdin closed (`< /dev/null`), `timeout 600` per `apt-get` call |
| Permission denied | Missing `sudo` | All system operations use `sudo`; append `|| true` |
| Disk space not freed | Path doesn't exist on runner | Check with `find` before removal; ARM64 has fewer pre-installed packages |

## Resources

- [GitHub Actions Docs](https://docs.github.com/en/actions) · [ShellCheck Wiki](https://www.shellcheck.net/wiki/) · [Bash Reference](https://www.gnu.org/software/bash/manual/) · [rmz (fuc)](https://github.com/SUPERCILEX/fuc)

---

**Maintained By**: Enderson Menezes (@endersonmenezes)
