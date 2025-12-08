# Free Disk Space - Action

![GitHub License](https://img.shields.io/github/license/endersonmenezes/free-disk-space?label=Project%20License)
![GitHub Actions Workflow Status](https://img.shields.io/github/actions/workflow/status/endersonmenezes/free-disk-space/testing.yaml)
![GitHub Release](https://img.shields.io/github/v/release/endersonmenezes/free-disk-space)
![pre-commit](https://img.shields.io/badge/pre--commit-enabled-brightgreen?logo=pre-commit)

A GitHub Action to free disk space on Ubuntu runners by removing unnecessary software and files.

> 💡 **For Contributors & AI Agents**: See [AGENTS.md](AGENTS.md) for technical details, development setup, and contribution guidelines.

## 📑 Table of Contents

- [Compatibility](#compatibility)
- [Available Options](#available-options)
- [What's New in v3](#whats-new-in-v3-)
- [Quick Start](#quick-start)
- [Common Use Cases](#common-use-cases)
- [Size Savings](#size-savings)
- [FAQ](#faq)
- [Contributing](#contributing)
- [Changelog](#changelog)

## Compatibility

- Ubuntu 22.04 - Tested on 21/08/2025.
- Ubuntu Latest (24.04) - Tested on 30/10/2025.

## Available Options

| Input | Description | Required | Default |
|-------|-------------|----------|---------|
| `principal_dir` | Principal directory to check disk space | No | `/` |
| `remove_android` | Remove Android SDK and libraries | No | `false` |
| `remove_dotnet` | Remove .NET runtime and SDKs | No | `false` |
| `remove_haskell` | Remove Haskell (GHC) | No | `false` |
| `remove_tool_cache` | Remove tool cache directory | No | `false` |
| `remove_swap` | Remove swap storage | No | `false` |
| `remove_packages` | Space-separated list of packages to remove | No | `false` |
| `remove_packages_one_command` | Remove all packages in one command | No | `false` |
| `remove_folders` | Space-separated list of folders to remove | No | `false` |
| `rm_cmd` | Removal command: `rm` (safe) or `rmz` (faster) | No | `rm` |
| `rmz_version` | Version of rmz to use (required if `rm_cmd=rmz`) | No | `3.1.1` |
| `testing` | Testing mode (echoes commands instead of running) | No | `false` |

## What's New in v3 🚀 (Working in Progress)

- **🔥 rmz Support**: Use `rmz` for up to 3x faster file deletion
- **🛠️ DevContainer**: Full development environment with Docker-in-Docker
- **✅ Pre-commit Hooks**: Automated code quality checks with shellcheck and actionlint
- **📦 Workflow Templates**: Refactored tests using reusable workflows
- **🔧 Better Error Handling**: Improved validation and error messages
- **📝 Enhanced Documentation**: Complete API reference and examples

### Migration from v2 to v3

The v3 is fully backward compatible with v2. To migrate:

```yaml
# Before (v2)
- uses: endersonmenezes/free-disk-space@v2
  with:
    remove_android: true

# After (v3) - works the same
- uses: endersonmenezes/free-disk-space@v3
  with:
    remove_android: true
    
# After (v3) - with new features
- uses: endersonmenezes/free-disk-space@v3
  with:
    remove_android: true
    rm_cmd: "rmz"        # NEW: Faster deletion
    rmz_version: "3.1.1" # NEW: Specify rmz version
```

**Breaking Changes:** None! All v2 configurations work in v3.

**New Optional Parameters:**
- `rm_cmd`: Choose between `rm` (default) or `rmz` (faster)
- `rmz_version`: Specify rmz version when using `rm_cmd: rmz`

## Inspiration

Free Disk Space Action are inspired by [jlumbroso/free-disk-space](https://github.com/jlumbroso/free-disk-space)

## Motivation

At work I came across a huge Docker image that still needed to be analyzed by a local security tool. This consumed the entire Runner and in addition to the repository I found, I needed to remove some packages, which led me to create a modification of the original repository.

I will maintain a Stable version of this project.

## Quick Start

```yaml
name: Free Disk Space (Ubuntu)
on:
  - push

jobs:
  free-disk-space:
    runs-on: ubuntu-latest
    steps:
      - name: Free Disk Space
        uses: endersonmenezes/free-disk-space@v3  # Use @main for latest, @v3 for stable
        with:
          remove_android: true
          remove_dotnet: true
          remove_haskell: true
          remove_tool_cache: true
          remove_swap: true
          remove_packages: "azure-cli google-cloud-cli microsoft-edge-stable google-chrome-stable firefox postgresql* temurin-* *llvm* mysql* dotnet-sdk-*"
          remove_packages_one_command: true
          remove_folders: "/usr/share/swift /usr/share/miniconda /usr/share/az* /usr/local/lib/node_modules /usr/local/share/chromium /usr/local/share/powershell /usr/local/julia /usr/local/aws-cli /usr/local/aws-sam-cli /usr/share/gradle"
          rm_cmd: "rm"  # Use 'rmz' for faster deletion (default: 'rm')
          rmz_version: "3.1.1"  # Required when rm_cmd is 'rmz'
          testing: false
```

## Common Use Cases

#### Docker Build with Large Images
```yaml
- name: Free Disk Space for Docker
  uses: endersonmenezes/free-disk-space@v3
  with:
    remove_android: true
    remove_dotnet: true
    remove_haskell: true
    rm_cmd: "rmz"  # Faster cleanup
    
- name: Build Docker Image
  run: docker build -t myapp:latest .
```

#### Node.js Project with Many Dependencies
```yaml
- name: Free Disk Space for Node
  uses: endersonmenezes/free-disk-space@v3
  with:
    remove_android: true
    remove_haskell: true
    remove_packages: "google-cloud-cli azure-cli"
    
- name: Install Dependencies
  run: npm ci
```

#### Python Data Science Workflow
```yaml
- name: Free Disk Space for Python
  uses: endersonmenezes/free-disk-space@v3
  with:
    remove_android: true
    remove_dotnet: true
    remove_folders: "/usr/share/swift /usr/local/julia"
    
- name: Install Python Packages
  run: pip install pandas numpy scikit-learn
```

### Performance Optimization with rmz

For faster file deletion, you can use `rmz` instead of the default `rm` command:

```yaml
- name: Free Disk Space (with rmz)
  uses: endersonmenezes/free-disk-space@v3
  with:
    remove_android: true
    remove_dotnet: true
    rm_cmd: "rmz"  # Faster deletion (~3x faster)
    rmz_version: "3.1.1"
```

**Note:** `rmz` is a Rust-based alternative to `rm`, providing significantly faster deletion for large directories. Learn more at [SUPERCILEX/fuc](https://github.com/SUPERCILEX/fuc).

## Size Savings

`Updated at: 30/10/2025 - Based on Run #197`

### Ubuntu Latest (x86_64)

| Option | Size Freed | Time (rm) | Time (rmz) | Notes |
|--------|------------|-----------|------------|-------|
| `remove_android` | ~10 GB | 54s | 13s | Part of Basic test |
| `remove_dotnet` | ~3 GB | Included | Included | Part of Basic test |
| `remove_haskell` | 6 GB | 14s | 3s | ⚡ **78% faster with rmz** |
| `remove_tool_cache` | 5 GB | 83s | 27s | ⚡ **67% faster with rmz** |
| `remove_swap` | - | - | - | Included in tool_cache test |
| `remove_packages` (example) | 5 GB | 69s | 43s | postgresql*, temurin-*, *llvm*, mysql*, dotnet-sdk-* |
| **Full cleanup** | **31 GB** | **184s** | **238s** | All options enabled |
| **Large removal** | **38 GB** | **538s** | **344s** | ⚡ **36% faster with rmz** |

### Ubuntu 24.04 ARM64

| Option | Size Freed | Time (rm) | Time (rmz) | Notes |
|--------|------------|-----------|------------|-------|
| `remove_android` | 0 GB | - | - | Not available on ARM |
| `remove_dotnet` | 0 GB | - | - | Not available on ARM |
| `remove_haskell` | 0 GB | - | - | Not available on ARM |
| `remove_tool_cache` | 0 GB | - | - | Not available on ARM |
| `remove_packages` (example) | 4 GB | 80s | 67s | ⚡ **16% faster with rmz** |
| **Full cleanup** | **3 GB** | **22s** | **45s** | Limited packages on ARM |
| **Large removal** | **6 GB** | **66s** | **82s** | Limited packages on ARM |

### Individual Folders (Both Architectures)

| Folder | Ubuntu Latest | Ubuntu ARM | Time (rm) | Time (rmz) | Notes |
|--------|---------------|------------|-----------|------------|-------|
| `/usr/share/swift` | 3 GB | 3 GB | 2s / 6s | 5s / 6s | Consistent across archs |
| `/usr/local/share/powershell` | 1 GB | 1 GB | 2s / 7s | 2s / 6s | ~1.2 GB |
| `/usr/local/lib/node_modules` | 0 GB | 1 GB | 15s / 20s | 10s / 22s | ~463 MB |
| `/usr/share/az*` | 0 GB | 1 GB | 6s / 8s | 3s / 6s | Azure CLI (~495 MB) |
| `/usr/share/miniconda` | 0 GB | 0 GB | 18s / 5s | 5s / 6s | ~736 MB (when present) |
| `/usr/local/aws-cli` | 0 GB | 0 GB | 7s | 6s | ~248 MB (when present) |
| `/usr/local/aws-sam-cli` | 0 GB | 0 GB | 16s | 7-8s | ⚡ **50% faster with rmz** |
| `/usr/local/share/chromium` | 0 GB | 0 GB | 4s | 2s | ~593 MB (when present) |
| `/usr/share/gradle` | 0 GB | 0 GB | 1s | 2s | ~143 MB (when present) |
| `/usr/local/julia` | 0 GB | 0 GB | 2-6s | 5-6s | ~1 GB (when present) |

_Times shown as: ubuntu-latest / ubuntu-arm64_

### Recommended Packages to Remove

**Ubuntu Latest (x86_64):**
```yaml
remove_packages: "azure-cli google-cloud-cli microsoft-edge-stable google-chrome-stable firefox postgresql* temurin-* *llvm* mysql* dotnet-sdk-*"
```

**Top packages by size:**
- `microsoft-edge-stable` - 617 MB
- `azure-cli` - 583 MB  
- `google-cloud-cli` - 523 MB
- `google-chrome-stable` - 386 MB
- `temurin-21-jdk` - 352 MB
- `firefox` - 274 MB
- `llvm-18-dev` - 329 MB

**Ubuntu ARM64:**
```yaml
remove_packages: "azure-cli dotnet-sdk-8.0 temurin-* *llvm* mysql* firefox"
```

**Top packages by size:**
- `azure-cli` - 583 MB
- `temurin-21-jdk` - 352 MB
- `dotnet-sdk-8.0` - 324 MB
- `llvm-18-dev` - 311 MB
- `firefox` - 253 MB

### Recommended Folders to Remove

**Ubuntu Latest (x86_64):**
```yaml
remove_folders: "/usr/share/swift /usr/share/miniconda /usr/share/az* /usr/local/lib/node_modules /usr/local/share/chromium /usr/local/share/powershell /usr/local/julia /usr/local/aws-cli /usr/local/aws-sam-cli /usr/share/gradle"
```

**Ubuntu ARM64:**
```yaml
remove_folders: "/usr/share/swift /usr/local/share/powershell /usr/local/lib/node_modules /usr/share/az* /usr/local/aws-cli"
```

### Performance Notes

- ⚡ **rmz is significantly faster** for large operations (up to 78% faster on Haskell removal)
- 🔧 **ARM runners have fewer pre-installed packages** (49 GB initial vs 23 GB on x86_64)
- 📊 **Full cleanup on x86_64** can free up to **38 GB** with Large removal
- 🎯 **For maximum speed**: Use `rmz` with `remove_packages_one_command: true`

_The time can vary according to multiple factors. These measurements are based on [Run #197](https://github.com/endersonmenezes/free-disk-space/actions/runs/18948864052)_

_In our action you can see more folders and packages to delete, but it is your responsibility to know what you are doing._

_Initially I created this project with the intention of doing all this and then being able to use Docker and Python, our tests will prove this._

## FAQ

**Q: Should I use rm or rmz?**
- Use `rm` (default) for compatibility and safety
- Use `rmz` when you need maximum performance

**Q: How much time does this save in my CI/CD?**
- Typical savings: 2-5 minutes per workflow run
- With rmz: Up to 3x faster deletion operations

**Q: Is it safe to remove all these packages?**
- The defaults are safe for most workflows
- Test with your specific needs first
- Use `testing: true` to see what would be removed

**Q: How can I debug issues?**
- Enable disk space logging before and after (see examples above)
- Use `testing: true` to see what would be removed without actually removing
- Check the [AGENTS.md](AGENTS.md) for troubleshooting details

## Contributing

We welcome contributions! Whether you're fixing bugs, adding features, or improving documentation, your help is appreciated.

**Quick Start:**
1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Open a Pull Request

**For detailed instructions**, see [AGENTS.md](AGENTS.md) which includes:
- Development setup (DevContainer & manual)
- Testing guidelines
- Code style standards
- Pre-commit hooks usage
- Architecture details

## Acknowledgements

This project, despite being on my personal profile purely formally, is part of an NGO we have in Brazil, responsible for helping young people and adults learn to program and tackle real-world projects. Learn more at [codaqui.dev](https://codaqui.dev).

## Changelog (YYYY-MM-DD)

### v3.1.0 (2025-12-08)

**CI/CD Improvements:**
- 🔧 Changed linter runner from `ubuntu-latest` to `ubuntu-slim` for faster execution
- 📊 Enhanced `search_biggest` job with multi-runner matrix (`ubuntu-24.04`, `ubuntu-22.04`, `ubuntu-24.04-arm`, `ubuntu-slim`)
- 📦 Added listing of top 50 packages by size and biggest files in key directories

**Test Reorganization:**
- 🧪 Added use case-based tests: Docker Build, Python/ML, Node.js, Java/JVM, Remove Browsers, Remove Cloud CLIs, Remove LLVM
- 🗂️ Replaced low-impact folder tests with high-impact ones (`/opt/hostedtoolcache`, `/usr/share/dotnet`, `/usr/local/.ghcup`, `/usr/local/lib/android`)

**Cleanup:**
- 🧹 Centralized package size listing in `search_biggest` job

### v3.0.0 (2025-10-30) 🚀

**New Features:**
- ✨ Added `rmz` support for faster file deletion (up to 3x faster)
  - ✨ Added `rm_cmd` and `rmz_version` inputs
  - 🔧 Multi-architecture support for rmz (x86_64 and aarch64)
- 🛠️ DevContainer configuration for easy development
- ✅ Pre-commit hooks with shellcheck and actionlint
- 📝 Enhanced documentation with examples and troubleshooting

**Improvements:**
- 🔧 Better error handling and validation
- 🔧 Improved testing mode (echo commands instead of alias)
- 📦 Reusable workflow templates for testing

**Bug Fixes:**
- 🐛 Fixed bc validation to exit gracefully instead of failing
- 🐛 Improved permission handling in testing mode

**Special Thanks:**
- [fbnrst](https://github.com/fbnrst) for contributions, ideas, and testing!

### v2.1.1 (2025-08-21)

**Improvements:**
- Streamlined BC verification
- Improved testing mode
- Better error messages

### v2.0.0

**Features:**
- Package removal support
- Folder removal support
- Enhanced disk space reporting
- Testing mode for local development

### v1.0.0

**Initial Release:**
- Android library removal
- .NET library removal
- Haskell library removal
- Tool cache removal
- Swap storage removal

## License

This project is licensed under the terms specified in the [LICENSE](LICENSE) file.