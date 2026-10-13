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

Measured by the `search_biggest` CI job and the test dashboard (October 2026):

| Aspect | x86_64 (22.04 / 24.04, maintenance only) | ARM64 (22.04 / 24.04, maintenance only) | `ubuntu-26.04` (GA; target of `ubuntu-latest`) | `ubuntu-26.04-arm` (GA) |
|--------|--------------------------------|------------------------|--------------------------|------------------------------|
| Initial free disk | ~86 GB | ~108 GB | ~91 GB | ~111 GB |
| Android SDK | Present (~11 GB) | Absent | Present (~11 GB) | Absent |
| .NET (`/usr/share/dotnet`) | Present | Present (~4 GB) | Present (~5.8 GB) | Present (~6.1 GB) |
| Haskell (`/usr/local/.ghcup`) | Present | Absent | Present (~3.7 GB) | Absent |
| Swift (`/usr/share/swift`) | Present | Present | Removed from image | Removed from image |
| Julia (`/usr/local/julia*`) / Miniconda | Present | Present | Removed from image | Removed from image |
| Pre-seeded container images | `/var/lib/docker` (~1.9 GB) | `/var/lib/docker` (~1.9 GB) | `/var/lib/containerd` (~2.6 GB) | `/var/lib/containerd` (~2.6 GB) |

`ubuntu-latest` migration: the label moves from Ubuntu 24.04 to 26.04 between 2026-10-19 and 2026-11-19 ([runner-images#14748](https://github.com/actions/runner-images/issues/14748)). The `ubuntu-22.04` / `ubuntu-24.04` labels (x86_64 and ARM64) remain available and are kept in the test matrices as **maintenance only** until GitHub retires them.

Public-repository runner specs (October 2026): standard Linux runners are 4 vCPU / 16 GB RAM. The single-CPU `ubuntu-slim` label (1 vCPU / 5 GB, unprivileged container, 15-min job timeout, minimal toolset) is used for the `shellcheck` job and is covered by `search_biggest`; it cannot run Docker-in-Docker or privileged mounts.

Notes on the 26.04 images:

- Toolchain bumps: LLVM 20/21/22 (was 16-18), Temurin 11/17/21/**25** (8 dropped), gcc 13/14/15 side by side, Python 3.14, kernel 7.0 (`linux-azure`).
- Azure CLI is split across three locations: `azure-cli` package, `/opt/az` and `/usr/share/az_*`.
- PowerShell is no longer a deb package on 26.04 — only `remove_folders` (`/usr/local/share/powershell`, ~1.4 GB) removes it there.
- On 26.04-arm, Google Cloud SDK moved to `/opt/google-cloud-sdk` (~890 MB) and is not a deb package — `remove_packages: google-cloud-cli` does not remove it there; use `remove_folders`.
- The 26.04 apt archive (`azure.archive.ubuntu.com/ubuntu resolute`) has been observed stalling mid-download; the `apt_get` wrapper bounds this with a 600s timeout.

Large items present on all current images but NOT covered by the action (candidates, measured October 2026): `/opt/runner-cache` (~1.3 GB x64 / ~820 MB arm — removal untested), CodeQL inside the tool cache (~1.4 GB, covered only by `remove_tool_cache`), `/opt/pipx` (~510 MB), and the tripled Rust toolchain (`/home/runner/.rustup`, `/etc/skel/.rustup`, `/home/packer`; ~2 GB combined). Pre-seeded container images live in `/var/lib/containerd` on 26.04 (~2.6 GB) — reclaiming them requires `docker system prune`, not `rm`.

Tests MUST pass on all architectures. Some cleanup functions are no-ops where the software is absent (e.g. Android/Haskell on ARM64, Swift on 26.04).

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
