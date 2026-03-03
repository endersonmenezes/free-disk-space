# Changelog

All notable changes to **Free Disk Space Action** are documented here.

Format follows [Keep a Changelog](https://keepachangelog.com/en/1.0.0/).  
Versioning follows [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

---

## [Unreleased]

**Changed:**
- 📊 Distinguish total free space from recovered space in output — fixes [#22](https://github.com/endersonmenezes/free-disk-space/issues/22) (`a89b4e5`)
- 🛠️ Update GitHub Actions extension identifier in devcontainer configuration (`a9a4807`)

**Fixed:**
- 🐛 Replace `bc` alias with variable path to prevent breakage when `bc` is relocated during cleanup (`0d73123`)
- 🐛 Replace Docker-based shellcheck with Python-based alternative in DevContainer (`eebb38f`)

**CI/CD Improvements:**
- 🧹 Remove user-reported full cleanup test from workflow jobs (`b40e4c8`)

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
