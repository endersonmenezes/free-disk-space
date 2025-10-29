# AGENTS.md - AI Agent Instructions

## 📋 Project Overview

This repository contains the **Free Disk Space** GitHub Action, a tool designed to free up disk space on GitHub Actions Ubuntu runners by removing unnecessary software, packages, and files.

### Basic Information

- **Type**: GitHub Action
- **Language**: Shell Script (Bash)
- **Target OS**: Ubuntu 22.04, Ubuntu Latest (24.04)
- **Main Script**: `main.sh`
- **Action Definition**: `action.yaml`
- **Repository**: https://github.com/endersonmenezes/free-disk-space
- **Maintainer**: Enderson Menezes (@endersonmenezes)

## 🎯 Project Objectives

1. **Disk Space Management**: Free up disk space on GitHub Actions runners
2. **Performance**: Optimize cleanup operations for speed and efficiency
3. **Flexibility**: Allow users to customize what gets removed
4. **Safety**: Provide testing mode for safe local development
5. **Compatibility**: Support multiple Ubuntu versions and architectures

## 📁 Project Structure

```
free-disk-space/
├── .devcontainer/          # DevContainer configuration
│   └── devcontainer.json   # VS Code container setup with Docker-in-Docker
├── .github/
│   └── workflows/
│       ├── testing.yaml              # Main test workflow
│       ├── test-template.yaml        # Reusable test template
│       └── quick-test-template.yaml  # Fast PR validation template
├── .pre-commit-config.yaml # Pre-commit hooks configuration
├── .shellcheckrc           # Shellcheck settings (enable=all)
├── action.yaml             # GitHub Action definition (inputs/outputs)
├── main.sh                 # Main cleanup script (executable)
├── README.md               # User documentation
├── AGENTS.md              # This file - AI agent instructions
└── LICENSE                # License file
```

## 🔧 Technical Configuration

### Action Inputs (action.yaml)

| Input | Type | Default | Description |
|-------|------|---------|-------------|
| `principal_dir` | string | `/` | Directory to check disk space |
| `remove_android` | boolean | `false` | Remove Android SDK |
| `remove_dotnet` | boolean | `false` | Remove .NET runtime |
| `remove_haskell` | boolean | `false` | Remove Haskell (GHC) |
| `remove_tool_cache` | boolean | `false` | Remove tool cache |
| `remove_swap` | boolean | `false` | Remove swap storage |
| `remove_packages` | string | `false` | Space-separated package list |
| `remove_packages_one_command` | boolean | `false` | Remove all packages at once |
| `remove_folders` | string | `false` | Space-separated folder list |
| `rm_cmd` | string | `rm` | Removal command: `rm` or `rmz` |
| `rmz_version` | string | `3.1.1` | rmz version (if using rmz) |
| `testing` | boolean | `false` | Testing mode (echo instead of execute) |

### Environment Variables (main.sh)

Required variables passed from action.yaml:
- `ANDROID_FILES`: Boolean for Android removal
- `DOTNET_FILES`: Boolean for .NET removal
- `HASKELL_FILES`: Boolean for Haskell removal
- `TOOL_CACHE_FILES`: Boolean for tool cache removal
- `SWAP_STORAGE`: Boolean for swap removal
- `PACKAGES`: String of packages to remove
- `REMOVE_ONE_COMMAND`: Boolean for single command removal
- `REMOVE_FOLDERS`: String of folders to remove
- `RM_CMD`: String (`rm` or `rmz`)
- `RMZ_VERSION`: String (semantic version)
- `TESTING`: Boolean for testing mode
- `AGENT_TOOLSDIRECTORY`: System directory for tools
- `PRINCIPAL_DIR`: Directory for disk space checks

### Architecture Support

- **x86_64** / **amd64**: Fully supported
- **aarch64** / **arm64**: Fully supported (for rmz)

## 📝 Code Standards & Directives

### 🚨 CRITICAL RULES - ALWAYS FOLLOW

#### 1. Shell Script Standards

```yaml
Naming Conventions:
  - Variables: UPPER_SNAKE_CASE (e.g., TOTAL_FREE_SPACE)
  - Functions: snake_case (e.g., remove_android_library_folder)
  - Constants: UPPER_SNAKE_CASE with readonly (e.g., readonly VERSION="3.0.0")

Code Style:
  - Always quote variables: "${VARIABLE}"
  - Use [[ ]] for conditionals, not [ ]
  - End all commands with || true for graceful degradation
  - Use sudo for system operations
  - Prefix function calls with explicit invocation
  
Error Handling:
  - Every removal operation must have || true
  - Exit with code 0 on validation failures (not 1)
  - Log errors to stderr when appropriate
  - Validate all inputs before processing
```

#### 2. ShellCheck Compliance (MANDATORY)

```bash
# Configuration (.shellcheckrc)
enable=all
disable=SC2032,SC2033

# Run before committing
shellcheck main.sh -o all -e SC2033,SC2032

# All code must pass shellcheck with these settings
```

**Common ShellCheck Rules:**
- SC2086: Quote variables to prevent word splitting
- SC2155: Declare and assign separately to avoid masking return values
- SC2164: Use `cd ... || exit` to handle cd failures
- SC1090: Dynamic sourcing is allowed with justification

#### 3. Testing Requirements

**Every function modification MUST:**
1. Pass existing tests
2. Include new test cases if behavior changes
3. Be tested in both `rm` and `rmz` modes
4. Be tested with `TESTING=true` mode

**Test Structure:**
```yaml
# Quick tests (PR validation)
quick_test_dotnet:      # Fast .NET removal test
quick_test_android:     # Fast Android removal test  
quick_test_packages:    # Fast package removal test
quick_test_testing_mode: # Testing mode validation

# Full tests (push/schedule)
test_basic:             # Basic cleanup operations
test_full:              # Full cleanup (all options)
test_packages_*:        # Package removal variations
test_folders:           # Folder removal
test_tool_cache_swap:   # Tool cache and swap
test_haskell:           # Haskell-specific
test_large_removal:     # Large-scale cleanup
```

#### 4. Function Structure Pattern

```bash
function function_name(){
    echo "🧹 Description of what this does"
    update_and_echo_free_space "before"
    
    # Actual removal operations with error handling
    run_rm -f /path/to/remove || true
    
    # Package removal if applicable
    PACKAGES=$(dpkg -l | grep -E "pattern" | awk '{print $2}' | tr '\n' ' ' || true)
    if [[ -n "${PACKAGES}" ]]; then
        sudo apt-get remove -y ${PACKAGES} || true
    fi
    
    update_and_echo_free_space "after"
    echo "-"
}
```

#### 5. rmz Implementation Rules

**Installation:**
```bash
# Must support both architectures
arch="$(uname -m)"
case "${arch}" in
    x86_64|amd64) ASSET="x86_64-unknown-linux-gnu-rmz" ;;
    aarch64|arm64) ASSET="aarch64-unknown-linux-gnu-rmz" ;;
    *) echo "Unsupported arch: ${arch}"; exit 0 ;;
esac

# Download atomically
tmpfile=$(mktemp)
if ! curl -fsSL -o "${tmpfile}" "${RMZ_RELEASE_URL}"; then
    echo "Failed to download rmz"
    rm -f "${tmpfile}"
    exit 0
fi
sudo install -m 0755 "${tmpfile}" /usr/local/bin/rmz
rm -f "${tmpfile}"
```

**Usage Wrapper:**
```bash
function run_rm() {
    if [[ "${TESTING:-false}" == "true" ]]; then
        if [[ "${RM_CMD}" == "rmz" ]]; then
            echo rmz "$@"
        else
            echo rm -r "$@"
        fi
        return 0
    fi

    if [[ "${RM_CMD}" == "rmz" ]]; then
        sudo rmz "$@"
    else
        sudo rm -r "$@"
    fi
}
```

#### 6. Validation Standards

**Input Validation:**
```bash
# All inputs must be validated
if [[ -z "${VARIABLE}" ]]; then
    echo "Variable VARIABLE is not set"
    exit 0  # Exit gracefully, not with error
fi

# Boolean validation
if [[ "${VARIABLE}" != "true" && "${VARIABLE}" != "false" ]]; then
    echo "Variable VARIABLE must be 'true' or 'false'"
    exit 0
fi

# Enum validation
if [[ "${RM_CMD}" != "rm" && "${RM_CMD}" != "rmz" ]]; then
    echo "Variable RM_CMD must be either 'rm' or 'rmz'"
    exit 0
fi

# Version validation
if ! [[ "${RMZ_VERSION}" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
    echo "RMZ_VERSION must be a semantic version like X.Y.Z"
    exit 0
fi
```

## 🤖 Instructions for AI Agents

### When Adding New Features

1. **Analyze Requirements**
   - Understand the disk space issue being solved
   - Identify target files/packages/folders
   - Check Ubuntu compatibility (22.04 and latest)
   - Consider performance impact

2. **Plan Implementation**
   ```bash
   # 1. Add input to action.yaml
   new_feature:
     description: "Description of feature"
     required: false
     default: "false"
   
   # 2. Pass to main.sh via environment
   env:
     NEW_FEATURE: ${{ inputs.new_feature }}
   
   # 3. Validate in main.sh
   if [[ -z "${NEW_FEATURE}" ]]; then
       echo "Variable NEW_FEATURE is not set"
       exit 0
   fi
   
   # 4. Implement function
   function remove_new_feature(){
       echo "🧹 Removing new feature"
       update_and_echo_free_space "before"
       run_rm -f /path/to/feature || true
       update_and_echo_free_space "after"
       echo "-"
   }
   
   # 5. Add to execution flow
   if [[ ${NEW_FEATURE} == true ]]; then
       remove_new_feature
   fi
   ```

3. **Write Tests**
   ```yaml
   # In .github/workflows/testing.yaml
   test_new_feature:
     needs: shellcheck
     if: github.event_name == 'push' || github.event_name == 'workflow_dispatch'
     uses: ./.github/workflows/test-template.yaml
     with:
       job_name: "New Feature Test"
       new_feature: true
   ```

4. **Update Documentation**
   - Add to README.md "Available Options" table
   - Add usage example
   - Add to Size Savings table if measurable
   - Update AGENTS.md with technical details

### When Fixing Bugs

1. **Reproduce Issue**
   - Test in `TESTING=true` mode locally
   - Verify in GitHub Actions environment
   - Check both `rm` and `rmz` modes if applicable

2. **Write Failing Test**
   ```yaml
   # Add test case that reproduces the bug
   test_bug_fix:
     uses: ./.github/workflows/test-template.yaml
     with:
       job_name: "Bug Fix Validation"
       # Configuration that triggers bug
   ```

3. **Fix Implementation**
   - Maintain backward compatibility
   - Follow error handling patterns
   - Add validation if input-related

4. **Verify Fix**
   - Run shellcheck
   - Run pre-commit hooks
   - Test locally with TESTING=true
   - Verify in CI

### When Optimizing Performance

1. **Measure Baseline**
   ```bash
   # Add timing to test workflows
   - name: Measure performance
     run: |
       start_time=$(date +%s)
       # ... operation ...
       end_time=$(date +%s)
       echo "Duration: $((end_time - start_time))s"
   ```

2. **Common Optimization Patterns**
   ```bash
   # Use rmz for large deletions
   if [[ "${RM_CMD}" == "rmz" ]]; then
       # 3x faster for large directories
       sudo rmz /large/directory
   fi
   
   # Batch package removal
   if [[ "${REMOVE_ONE_COMMAND}" == "true" ]]; then
       # Faster than individual removals
       sudo apt-get remove -y ${ALL_PACKAGES}
   fi
   
   # Minimize disk space checks
   # Only before/after, not during operations
   ```

3. **Test Performance Impact**
   - Compare before/after timing
   - Check memory usage (GitHub runner limits)
   - Verify disk space freed is consistent

### When Reviewing Code

**Checklist:**
- [ ] ShellCheck passes respecting .shellcheckrc
- [ ] All variables quoted: `"${VAR}"`
- [ ] Validation for new inputs
- [ ] Testing mode compatible
- [ ] Works with both `rm` and `rmz`
- [ ] Functions follow naming convention
- [ ] Comments explain complex logic
- [ ] Tests added/updated
- [ ] Documentation updated
- [ ] Backward compatible

## 🛠️ Development Workflow

### Local Development Setup

#### Using DevContainer (Recommended)

```bash
# 1. Open in VS Code
code .

# 2. Install "Dev Containers" extension
# 3. Press F1 → "Dev Containers: Reopen in Container"

# Container includes:
# - Docker-in-Docker
# - pre-commit hooks
# - shellcheck
# - VS Code extensions (shellcheck, GitHub Actions)
```

#### Manual Setup

```bash
# 1. Install dependencies
brew install shellcheck  # macOS
# or
apt-get install shellcheck  # Ubuntu

# 2. Install pre-commit
pip install pre-commit

# 3. Install hooks
pre-commit install

# 4. Test script locally
export TESTING=true
export PRINCIPAL_DIR=/
export ANDROID_FILES=true
export DOTNET_FILES=false
export HASKELL_FILES=false
export TOOL_CACHE_FILES=false
export SWAP_STORAGE=false
export PACKAGES=false
export REMOVE_ONE_COMMAND=false
export REMOVE_FOLDERS=false
export RM_CMD=rm
export RMZ_VERSION=3.1.1
export AGENT_TOOLSDIRECTORY=/usr/local/bin

bash main.sh
```

### Pre-commit Hooks

```yaml
# .pre-commit-config.yaml includes:

1. shellcheck:
   - Validates shell script syntax
   - Checks for common mistakes
   - Ensures best practices

2. check-yaml:
   - Validates YAML syntax
   - Checks for formatting issues

3. actionlint:
   - Validates GitHub Actions workflows
   - Checks for workflow errors
```

**Run manually:**
```bash
# All hooks
pre-commit run --all-files

# Specific hook
pre-commit run shellcheck --all-files
pre-commit run actionlint --all-files
```

### Testing Strategy

#### Test Matrix

```yaml
# Ubuntu versions
- ubuntu-latest (24.04)
- ubuntu-22.04

# Test types
- Quick tests (PR): Fast validation
- Full tests (push/schedule): Comprehensive coverage

# Test scenarios
- Individual features (android, dotnet, haskell)
- Combined features (full cleanup)
- Package removal (one command vs individual)
- Folder removal
- Edge cases (empty packages, invalid input)
- Performance tests (large removal)
```

#### Writing Tests

```yaml
# Quick test template (for PRs)
quick_test_feature:
  needs: shellcheck
  if: github.event_name == 'pull_request'
  uses: ./.github/workflows/quick-test-template.yaml
  with:
    job_name: "Feature Name"
    remove_feature: true
    # Minimal other options for speed

# Full test template (for push/schedule)
test_feature:
  needs: shellcheck
  if: github.event_name == 'push' || github.event_name == 'workflow_dispatch'
  uses: ./.github/workflows/test-template.yaml
  with:
    job_name: "Feature Name"
    remove_feature: true
    # Can include more comprehensive options
```

### Git Workflow

```bash
# 1. Create feature branch
git checkout -b feat/new-feature
# or
git checkout -b fix/bug-description

# 2. Make changes
# Edit main.sh, action.yaml, tests, docs

# 3. Run pre-commit (automatic)
git add .
git commit -m "feat: add new feature"
# Pre-commit runs automatically

# 4. If pre-commit fails
# Fix issues, then:
git add .
git commit -m "feat: add new feature"

# 5. Push
git push origin feat/new-feature

# 6. Create PR
# Tests will run automatically
```

### Commit Message Convention

```
type(scope): description

Types:
- feat: New feature
- fix: Bug fix
- docs: Documentation only
- style: Code style (formatting, no logic change)
- refactor: Code refactoring
- test: Adding or updating tests
- chore: Maintenance tasks

Examples:
feat(rmz): add rmz support for faster deletion
fix(android): handle missing android directories gracefully
docs(readme): add troubleshooting section
test(packages): add edge case for empty package list
chore(deps): update rmz version to 3.1.1
```

## 🔍 Troubleshooting Guide for Agents

### Common Issues and Solutions

#### Issue: "bc is not installed"

**Diagnosis:**
```bash
# Check if bc is available
command -v bc || echo "bc not found"
```

**Solution:**
```bash
# Script handles gracefully
if ! [[ -x "${COMMAND_BC}" ]]; then
    echo 'bc is not installed.'
    exit 0  # Exit gracefully, not error
fi
```

#### Issue: rmz installation fails

**Diagnosis:**
```bash
# Check architecture
uname -m

# Check network connectivity
curl -fsSL https://github.com/SUPERCILEX/fuc/releases
```

**Solution:**
```bash
# Fallback to rm
if ! [[ -x "${COMMAND_RMZ}" ]]; then
    echo 'rmz is not installed or not executable.'
    exit 0  # Will use rm instead
fi
```

#### Issue: Permission denied

**Diagnosis:**
```bash
# Check sudo availability
sudo -n true 2>/dev/null && echo "Sudo available" || echo "Sudo not available"
```

**Solution:**
```bash
# All system operations use sudo
sudo rm -rf /path/to/remove || true
sudo apt-get remove -y package || true
```

#### Issue: Disk space not freed

**Diagnosis:**
```bash
# Check what exists before removal
find /usr/share -name "*dotnet*" -type d 2>/dev/null
dpkg -l | grep -i dotnet

# Check after removal
find /usr/share -name "*dotnet*" -type d 2>/dev/null || echo "Removed"
```

**Solution:**
```bash
# Ensure removal paths are correct
# Ensure packages exist before trying to remove
PACKAGES=$(dpkg -l | grep -E "pattern" | awk '{print $2}' | tr '\n' ' ' || true)
if [[ -n "${PACKAGES}" ]]; then
    sudo apt-get remove -y ${PACKAGES} || true
fi
```

## 📚 Resources

### Documentation
- [GitHub Actions Documentation](https://docs.github.com/en/actions)
- [ShellCheck Wiki](https://www.shellcheck.net/wiki/)
- [Bash Reference Manual](https://www.gnu.org/software/bash/manual/)
- [rmz (fuc) Repository](https://github.com/SUPERCILEX/fuc)

### Project-Specific
- `README.md` - User-facing documentation
- `action.yaml` - Action input/output definitions
- `main.sh` - Main script implementation
- `.github/workflows/` - Test workflows

### Tools
- **ShellCheck**: Shell script static analysis
- **actionlint**: GitHub Actions workflow linter
- **pre-commit**: Git hook framework

## 🎯 Best Practices for AI Agents

### DO ✅

- **Always test locally first** with `TESTING=true`
- **Run shellcheck** before committing
- **Use pre-commit hooks** to catch issues early
- **Write tests** for new features
- **Update documentation** when changing behavior
- **Follow error handling patterns** with `|| true`
- **Validate inputs** before processing
- **Maintain backward compatibility**
- **Use meaningful commit messages**
- **Test both rm and rmz modes**

### DON'T ❌

- **Don't exit with error codes** for expected conditions (use exit 0)
- **Don't skip input validation** (can cause unexpected behavior)
- **Don't hardcode paths** that might not exist
- **Don't use echo for testing mode** without checking TESTING variable
- **Don't modify action.yaml** without updating main.sh
- **Don't commit without running pre-commit**
- **Don't break backward compatibility** without major version bump
- **Don't add features** without tests
- **Don't forget to update Size Savings** table

## 🔄 Version Management

### Semantic Versioning

```
vMAJOR.MINOR.PATCH

MAJOR: Breaking changes (e.g., remove input, change behavior)
MINOR: New features (backward compatible)
PATCH: Bug fixes, documentation, performance improvements
```

### Branch Strategy

```
main:     Stable releases (v3.0.0, v3.1.0, ...)
develop:  Development branch (optional)
feat/*:   Feature branches
fix/*:    Bug fix branches
```

## 💡 Advanced Topics

### Custom Deletion Functions

```bash
# Template for adding new removal function
function remove_custom_software(){
    echo "🧹 Removing Custom Software"
    update_and_echo_free_space "before"
    
    # Directory removal
    run_rm -f /path/to/software || true
    run_rm -f /opt/software || true
    
    # Package removal
    CUSTOM_PACKAGES=$(dpkg -l | grep -E "^ii.*custom" | awk '{print $2}' | tr '\n' ' ' || true)
    if [[ -n "${CUSTOM_PACKAGES}" ]]; then
        echo "Removing packages: ${CUSTOM_PACKAGES}"
        sudo apt-get remove -y ${CUSTOM_PACKAGES} || true
    fi
    
    update_and_echo_free_space "after"
    echo "-"
}
```

### Performance Profiling

```bash
# Add to test workflows for profiling
- name: Profile performance
  run: |
    echo "=== BEFORE ==="
    df -h
    du -sh /usr/share/* | sort -h | tail -20
    
    start_time=$(date +%s)
    # ... operation ...
    end_time=$(date +%s)
    
    echo "=== AFTER ==="
    df -h
    echo "Duration: $((end_time - start_time))s"
```

### Multi-Architecture Support

```bash
# Pattern for architecture-specific operations
arch="$(uname -m)"
case "${arch}" in
    x86_64|amd64)
        echo "Running on x86_64"
        # x86_64-specific logic
        ;;
    aarch64|arm64)
        echo "Running on aarch64"
        # aarch64-specific logic
        ;;
    *)
        echo "Unsupported architecture: ${arch}"
        exit 0
        ;;
esac
```

## 📞 Support & Community

### When You Need Help

1. **Check documentation**: README.md, AGENTS.md, code comments
2. **Search issues**: Existing issues might have solutions
3. **Check discussions**: Community Q&A
4. **Review test failures**: CI logs often show the issue
5. **Test locally**: Use TESTING=true to debug

### Creating Issues

```markdown
## Description
Clear description of the issue or feature request

## Environment
- OS: Ubuntu 22.04 / Ubuntu Latest
- Action Version: v3.0.0
- rm_cmd: rm / rmz

## Steps to Reproduce
1. Configure action with...
2. Run workflow
3. See error

## Expected Behavior
What should happen

## Actual Behavior
What actually happens

## Logs
```yaml
# Relevant workflow logs or error messages
```

## Additional Context
Any other relevant information
```

## 🏆 Contributors

This project is maintained by **Enderson Menezes** and the community.

Special thanks to:
- [jlumbroso](https://github.com/jlumbroso) for the original free-disk-space action
- [SUPERCILEX](https://github.com/SUPERCILEX) for the rmz tool
- All contributors who have helped improve this project

## 🎓 Learning Resources

### For New Contributors

1. **Learn Bash**: [Bash Guide](https://mywiki.wooledge.org/BashGuide)
2. **Learn ShellCheck**: [ShellCheck Wiki](https://www.shellcheck.net/wiki/)
3. **Learn GitHub Actions**: [Actions Docs](https://docs.github.com/en/actions)
4. **Review main.sh**: Understand the codebase
5. **Run tests**: See how tests work
6. **Start small**: Fix typos, update docs, then add features

### Key Concepts

- **GitHub Actions**: Automation platform for CI/CD
- **Shell Scripting**: Bash programming for system automation
- **Error Handling**: Graceful degradation with || true
- **Testing**: Automated validation of functionality
- **DevContainers**: Reproducible development environments

---

**Last Updated Agents.md**: 2025-10-23  
**Version**: 1.0.0
**Maintained By**: Enderson Menezes (@endersonmenezes)  
**License**: See LICENSE file
