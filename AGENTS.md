# AGENTS.md — Free Disk Space Action

Deep technical reference for contributors and AI agents. For coding conventions, standards, and project overview, see [`.github/copilot-instructions.md`](.github/copilot-instructions.md). For user-facing documentation, see [README.md](README.md).

## AI Customization Files

| File | Purpose |
|------|---------|
| `.github/copilot-instructions.md` | Project conventions, coding standards, testing strategy (always loaded) |
| `.github/agents/disk-space-engineer.agent.md` | Custom agent: workflows, behavioral rules, task feedback |
| `.github/skills/changelog-maintainer/SKILL.md` | Skill for maintaining changelog entries |

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

## ARM64 Differences

| Aspect | x86_64 (`ubuntu-latest`) | ARM64 (`ubuntu-24.04-arm`) |
|--------|--------------------------|---------------------------|
| Initial disk used | ~49 GB | ~23 GB |
| Android SDK | Present | Absent |
| .NET runtime | Present | Absent |
| Haskell (GHC) | Present | Absent |
| Tool cache | Smaller | Smaller |

Tests MUST pass on both architectures. Some cleanup functions are no-ops on ARM64.

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
  REMOVE_ONE_COMMAND=false REMOVE_FOLDERS=false RM_CMD=rm RMZ_VERSION=3.1.1 \
  AGENT_TOOLSDIRECTORY=/usr/local/bin
bash main.sh
```

## Troubleshooting

| Issue | Cause | Solution |
|-------|-------|---------|
| "bc is not installed" | `bc` removed by `apt-get` | Script copies `bc` to `./bc` before cleanup — handled automatically |
| rmz installation fails | Network or unsupported arch | Script exits gracefully (`exit 0`), user can fall back to `rm` |
| Permission denied | Missing `sudo` | All system operations use `sudo`; append `|| true` |
| Disk space not freed | Path doesn't exist on runner | Check with `find` before removal; ARM64 has fewer pre-installed packages |

## Resources

- [GitHub Actions Docs](https://docs.github.com/en/actions) · [ShellCheck Wiki](https://www.shellcheck.net/wiki/) · [Bash Reference](https://www.gnu.org/software/bash/manual/) · [rmz (fuc)](https://github.com/SUPERCILEX/fuc)

---

**Maintained By**: Enderson Menezes (@endersonmenezes)
