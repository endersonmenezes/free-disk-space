# GitHub Copilot Instructions — Free Disk Space Action

## Project Overview

This repository contains the **Free Disk Space** GitHub Action — a composite action (shell script) that frees disk space on GitHub Actions Ubuntu runners by removing unnecessary software, packages, and files.

- **Type**: GitHub Action (composite)
- **Language**: Bash (`main.sh`)
- **Action Definition**: `action.yaml`
- **Target OS**: Ubuntu 22.04, Ubuntu Latest (24.04), Ubuntu 26.04 (preview), ARM64
- **Repository**: `endersonmenezes/free-disk-space`

## Repository Structure

```
free-disk-space/
├── .github/
│   ├── agents/                         # Custom Copilot agents
│   │   └── disk-space-engineer.agent.md
│   ├── copilot-instructions.md         # This file
│   ├── skills/                         # Agent skills
│   │   └── changelog-maintainer/
│   │       └── SKILL.md
│   └── workflows/
│       ├── testing.yaml                # Main CI workflow
│       ├── test-template.yaml          # Reusable full test
│       └── quick-test-template.yaml    # Reusable PR quick test
├── .devcontainer/devcontainer.json
├── .editorconfig
├── .pre-commit-config.yaml
├── .shellcheckrc
├── action.yaml          # GitHub Action inputs/outputs
├── main.sh              # Main cleanup script
├── AGENTS.md            # Detailed AI agent instructions
├── README.md            # User documentation
└── LICENSE
```

## Code Conventions

### Shell Script (main.sh)

- **Variables**: `UPPER_SNAKE_CASE` (e.g., `TOTAL_FREE_SPACE`)
- **Functions**: `snake_case` (e.g., `remove_android_library_folder`)
- **Quoting**: Always `"${VARIABLE}"` — never unquoted
- **Conditionals**: `[[ ]]` not `[ ]`
- **Error handling**: Append `|| true` to removal operations
- **Exit codes**: Use `exit 0` for validation failures (graceful degradation)
- **Indentation**: 4 spaces (`.editorconfig`)

### YAML Files (workflows, action.yaml)

- **Indentation**: 2 spaces
- **Naming**: `kebab-case` for file names
- **Reusable workflows**: Prefer `workflow_call` templates

### ShellCheck (mandatory)

All code must pass: `shellcheck main.sh -o all -e SC2033,SC2032`

See `.shellcheckrc` for configuration.

### Commit Messages (Conventional Commits)

```
<type>(<scope>): <subject>

Types: feat, fix, docs, style, refactor, test, chore
Scopes: action, script, tests, workflows, docs, deps
```

## Action Inputs

| Input | Default | Purpose |
|-------|---------|---------|
| `principal_dir` | `/` | Directory to check disk space |
| `remove_android` | `false` | Remove Android SDK |
| `remove_dotnet` | `false` | Remove .NET runtime |
| `remove_haskell` | `false` | Remove Haskell (GHC) |
| `remove_tool_cache` | `false` | Remove tool cache |
| `remove_swap` | `false` | Remove swap storage |
| `remove_packages` | `false` | Space-separated package list |
| `remove_packages_one_command` | `false` | Remove all packages at once |
| `remove_folders` | `false` | Space-separated folder list |
| `rm_cmd` | `rm` | `rm` (safe) or `rmz` (faster) |
| `rmz_version` | `3.1.1` | rmz version when using rmz |
| `testing` | `false` | Echo commands instead of running |

## Testing Strategy

### Test Matrix

Every test runs on a matrix: `{rm, rmz} × {ubuntu-latest, ubuntu-22.04, ubuntu-24.04-arm, ubuntu-26.04 (preview), ubuntu-26.04-arm (preview)}`.

- **Quick tests** (`quick-test-template.yaml`): Run on PRs. Fast validation of key features.
- **Full tests** (`test-template.yaml`): Run on push/schedule. Comprehensive coverage with disk space metrics.
- **Use-case tests**: Real-world scenarios (Docker builds, Python/ML, Node.js, Java/JVM).

### Adding Tests

1. Add a new job in `.github/workflows/testing.yaml`
2. Use the appropriate reusable template (`test-template.yaml` or `quick-test-template.yaml`)
3. Wire correct inputs matching `action.yaml` parameters

### Writing New Functions in main.sh

Follow the standard pattern:

```bash
function function_name(){
    echo "🧹 Description"
    update_and_echo_free_space "before"
    run_rm -f /path/to/remove || true
    update_and_echo_free_space "after"
    echo "-"
}
```

## Key Technical Details

- **rmz**: Rust-based fast rm alternative from [SUPERCILEX/fuc](https://github.com/SUPERCILEX/fuc). Supports x86_64 and aarch64.
- **`run_rm` wrapper**: Handles `rm`/`rmz` switching and testing mode echo.
- **`bc` dependency**: Copied to local `./bc` before any `apt-get remove` to avoid self-destruction.
- **Disk space tracking**: `update_and_echo_free_space` measures before/after with `df -B1` and `bc`.

## Versioning

Semantic Versioning: `vMAJOR.MINOR.PATCH`

- **MAJOR**: Breaking changes
- **MINOR**: New features (backward compatible)
- **PATCH**: Bug fixes, docs, performance

## Development Workflow

1. Run `pre-commit install` once
2. Edit `main.sh` / `action.yaml` / workflows
3. Run `shellcheck main.sh -o all -e SC2033,SC2032` locally
4. Test with `TESTING=true` environment
5. Commit with Conventional Commits
6. Pre-commit hooks validate automatically

## Reference

- Full technical details: [AGENTS.md](../AGENTS.md)
- User documentation: [README.md](../README.md)
