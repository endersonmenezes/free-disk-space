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
- Ubuntu Latest (24.04) - Tested on 21/08/2025.

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

`Updated at: 01/08/2025`

| Option | Estimated Size | Time (For some cases) |
| ------ | -------------- | ---- |
| remove_android | 9543.16 MB | 52s |
| remove_dotnet | 32.32 MB MB | 4s |
| remove_haskell | 6460.36 MB | 2s-3s |
| remove_tool_cache | 4844.27 MB | 17s |
| remove_swap | # | # |
| remove_packages_one_command (Example Provided) | 7495.33 MB | 94s |
| folder: /usr/share/swift | 2773.80 MB | # |
| folder: /usr/share/miniconda | 736.06 MB | 9s |
| folder: /usr/share/az | 495.38 MB | 1s |
| folder: /usr/local/lib/node_modules | 463.80 MB | 10s |
| folder: /usr/local/share/chromium | 592.81 MB | 0s |
| folder: /usr/local/share/powershell | 1244.12 MB | 0s |
| folder: /usr/local/aws-cli | 248.41 MB | 1s |
| folder: /usr/local/aws-sam-cli | 189.50 MB | 1s |

_The time can vary according to multiple factors this estimed time based on the run: [#134](https://github.com/endersonmenezes/free-disk-space/actions/runs/16681335178/job/47220484686)_

_In our action you can see more folders and packages to delete, but is your responsibility to know what you are doing._

_Initially I created this project with the intention of doing all this and then being able to use Docker and Python, our tests will prove this._

### Disk After

```text
Run df -h
Filesystem      Size  Used Avail Use% Mounted on
/dev/root        72G   11G   62G  15% /
tmpfs           7.9G   84K  7.9G   1% /dev/shm
tmpfs           3.2G  1.1M  3.2G   1% /run
tmpfs           5.0M     0  5.0M   0% /run/lock
/dev/sda16      881M   60M  760M   8% /boot
/dev/sda15      105M  6.2M   99M   6% /boot/efi
/dev/sdb1        74G   28K   70G   1% /mnt
tmpfs           1.6G   12K  1.6G   1% /run/user/1001
```

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

## Changelog

### v3.0.0 (2025-XX-XX) 🚀 (Work In Progress)

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