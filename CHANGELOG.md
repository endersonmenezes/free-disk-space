# Changelog

All notable changes to **Free Disk Space Action** are documented here.

Format follows [Keep a Changelog](https://keepachangelog.com/en/1.0.0/).  
Versioning follows [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

---

## [Unreleased]

---

## [v3.2.2] — 2026-03-03 — Commit: `5eabf23`

**Changed:**
- 🤖 Enhance release-manager skill with terminal gotchas, tag-first workflow, CHANGELOG-based release notes, and updated agent DO/DON'Ts (`5eabf23`)

---

## [v3.2.1] — 2026-03-03 — Commit: `9cf1114`

**Added:**
- 🤖 Add Release Manager skill for managing semantic version releases and updating major version alias (`9cf1114`)

**Changed:**
- 📝 Update CHANGELOG.md and README.md with recent changes and performance improvements (`dcf58cd`)

---

## [v3.2.0] — 2026-03-03 — Commit: `f63fea6`

**Added:**
- 🧪 Add support for Ubuntu 22.04 in workflow templates and update README with compatibility badges (`2c1f01a`)
- 📝 Create CHANGELOG.md and update README to link to it (`19c7ae6`)
- 🤖 Add Copilot instructions and agent documentation (`403e664`)
- 🤖 Add Changelog Maintainer skill to automate CHANGELOG.md updates (`c7496bb`)

**Changed:**
- 📊 Distinguish total free space from recovered space in output — fixes [#22](https://github.com/endersonmenezes/free-disk-space/issues/22) (`a89b4e5`)
- 🛠️ Update GitHub Actions extension identifier in devcontainer configuration (`a9a4807`)
- 🔧 Update workflow templates and improve cleanup validation (`225faab`)
- 🔧 Update disk-space-engineer agent tools for enhanced functionality (`4ef9f03`)
- 🔄 Pre-commit autoupdate (`17f6375`)

**Fixed:**
- 🐛 Replace `bc` alias with variable path to prevent breakage when `bc` is relocated during cleanup (`0d73123`)
- 🐛 Replace Docker-based shellcheck with Python-based alternative in DevContainer (`eebb38f`)

**CI/CD Improvements:**
- 🧹 Remove user-reported full cleanup test from workflow jobs (`b40e4c8`)
- 🧪 Expand folder removal list in package removal tests for improved cleanup (`f63fea6`)

**Special Thanks:**
- [cuiyf5516](https://github.com/cuiyf5516) for fixing the `bc` path issue on Ubuntu 22.04 ([#27](https://github.com/endersonmenezes/free-disk-space/pull/27)) — first contribution! 🎉

---

## [v3.1.0] — 2025-12-08 — Commit: `e6ed9b0`

**Added:**
- 🧪 Use case-based tests: Docker Build, Python/ML, Node.js, Java/JVM, Remove Browsers, Remove Cloud CLIs, Remove LLVM
- 🗂️ Replaced low-impact folder tests with high-impact ones (`/opt/hostedtoolcache`, `/usr/share/dotnet`, `/usr/local/.ghcup`, `/usr/local/lib/android`)

**Changed:**
- 🧹 Centralized package size listing in `search_biggest` job

**CI/CD Improvements:**
- 🔧 Changed linter runner from `ubuntu-latest` to `ubuntu-slim` for faster execution
- 📊 Enhanced `search_biggest` job with multi-runner matrix (`ubuntu-24.04`, `ubuntu-22.04`, `ubuntu-24.04-arm`, `ubuntu-slim`)
- 📦 Added listing of top 50 packages by size and biggest files in key directories

---

## [v3.0.0] — 2025-10-30 — Commit: `6c4664f`

**Added:**
- ✨ `rm_cmd` input: choose between `rm` (default) or `rmz` (up to 3x faster deletion)
- ✨ `rmz_version` input: specify rmz version when using `rm_cmd: rmz`
- 🔧 Multi-architecture support for rmz (x86_64 and aarch64)
- 🛠️ DevContainer configuration for easy development
- ✅ Pre-commit hooks with shellcheck and actionlint
- 📦 Reusable workflow templates for testing

**Changed:**
- 🔧 Improved testing mode (echo commands instead of alias)
- 📝 Enhanced documentation with examples and troubleshooting

**Fixed:**
- 🐛 Fixed `bc` validation to exit gracefully instead of failing
- 🐛 Improved permission handling in testing mode

**Special Thanks:**
- [fbnrst](https://github.com/fbnrst) for contributions, ideas, and testing!

---

## [v2.1.1] — 2025-08-21 — Commit: `713d134`

**Changed:**
- 🔧 Streamlined BC verification
- 🔧 Improved testing mode
- 🔧 Better error messages

---

## [v2.0.0] — 2025-08-01 — Commit: `dd13eb4`

**Added:**
- 🆕 Package removal support (`remove_packages`)
- 🆕 Folder removal support (`remove_folders`)
- 📊 Enhanced disk space reporting
- 🧪 Testing mode for local development

---

## [v1.0.0] — 2024-02-16 — Commit: `d0b39f9`

**Added:**
- 🆕 Android library removal (`remove_android`)
- 🆕 .NET library removal (`remove_dotnet`)
- 🆕 Haskell library removal (`remove_haskell`)
- 🆕 Tool cache removal (`remove_tool_cache`)
- 🆕 Swap storage removal (`remove_swap`)
