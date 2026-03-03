# Skill: Changelog Maintainer

## Description

Maintains the CHANGELOG.md for the Free Disk Space GitHub Action following [Keep a Changelog](https://keepachangelog.com/en/1.0.0/) format and Semantic Versioning. Analyzes git changes since the last documented release, categorizes them, and generates properly formatted changelog entries.

## When to Use

Trigger this skill when:
- User asks to "update changelog", "prepare release", or "document changes"
- User mentions "what changed since last release"
- User requests "generate changelog entry" or "prepare version bump"
- Before creating a new release tag
- After a batch of commits that should be documented

## IMPORTANT: Not Every Commit is Notable

**Not all commits deserve a CHANGELOG entry.** The CHANGELOG documents notable changes for users/consumers of the action, not every internal commit.

### Notable Changes (Include in CHANGELOG)

✅ **Do include:**
- New action inputs or features
- New cleanup targets (packages, folders, tools)
- Performance improvements with measurable impact
- Bug fixes affecting action behavior
- Breaking changes (removed inputs, changed defaults)
- New test coverage for use cases
- Compatibility changes (new Ubuntu versions, new architectures)
- Dependency updates that affect behavior (rmz version bumps)
- Changes to Size Savings table data

❌ **Do NOT include:**
- Typo fixes in comments or documentation prose
- Formatting/whitespace changes in shell script
- Internal refactoring without behavior change
- Skill or agent configuration updates
- Pre-commit hook version bumps
- CI workflow reorganization without test changes
- Changelog formatting fixes

### When in Doubt: Ask the User

If uncertain whether a change is notable, ask the user before including or excluding it from the CHANGELOG.

## Workflow

### 1. Determine Last Documented Version

Read `README.md` and look for the most recent changelog entry:

```markdown
### vX.Y.Z (YYYY-MM-DD)
```

Also check `VERSION` file if present, and git tags:

```bash
git tag --sort=-v:refname | head -5
```

### 2. Gather Changes Since Last Release

```bash
# Find the last tag
LAST_TAG=$(git tag --sort=-v:refname | head -1)

# List changed files
git diff "${LAST_TAG}"..HEAD --name-status

# Full diff for analysis
git log "${LAST_TAG}"..HEAD --oneline

# Detailed commit messages
git log "${LAST_TAG}"..HEAD --pretty=format:"%h %s"
```

If no tags exist, use the initial commit:
```bash
git log --oneline
```

### 3. Categorize Changes

Map each change to the appropriate category based on files affected:

| File(s) Changed | Likely Category |
|-----------------|----------------|
| `main.sh` (new function) | **Added** — New cleanup feature |
| `main.sh` (modified function) | **Changed** or **Fixed** |
| `action.yaml` (new input) | **Added** — New action input |
| `action.yaml` (modified input) | **Changed** — Input behavior change |
| `action.yaml` (removed input) | **Removed** — BREAKING CHANGE |
| `.github/workflows/testing.yaml` | **Added** or **Changed** — Test improvements |
| `.github/workflows/*-template.yaml` | **Changed** — Test infrastructure |
| `README.md` (size savings) | **Changed** — Updated metrics |
| `README.md` (new examples) | **Added** — Documentation |
| `.pre-commit-config.yaml` | Usually not notable (skip) |
| `.github/agents/`, `.github/skills/` | Usually not notable (skip) |

### 4. Determine Version Bump

| Change Type | Version Bump | Example |
|-------------|-------------|---------|
| Breaking change (removed input, changed default) | **MAJOR** | v2 → v3 |
| New feature (new input, new cleanup target) | **MINOR** | v3.0 → v3.1 |
| Bug fix, docs, performance | **PATCH** | v3.1.0 → v3.1.1 |

### 5. Generate Changelog Entry

Use Keep a Changelog format with these section headers:

```markdown
### vX.Y.Z (YYYY-MM-DD)

**Added:**
- 🆕 New features, inputs, cleanup targets

**Changed:**
- 🔧 Modifications to existing behavior

**Fixed:**
- 🐛 Bug fixes

**Removed:**
- 🗑️ Removed features or inputs

**CI/CD Improvements:**
- 🧪 Test changes, workflow improvements

**Documentation:**
- 📝 Significant documentation updates
```

Rules:
- Use present tense ("Add", not "Added" in descriptions)
- Start each bullet with an emoji for visual scanning
- Group related changes together
- Reference specific inputs, functions, or paths
- For breaking changes, add migration instructions
- Include the date in ISO format (YYYY-MM-DD)
- Only include sections that have entries (skip empty sections)

### 6. Format for CHANGELOG.md

The changelog lives in `CHANGELOG.md` (root of the repository). Entries are ordered newest-first under the top-level heading. `README.md` has a `## Changelog` section with a single link to `CHANGELOG.md`.

Example output:

```markdown
## [v3.2.0] — 2026-03-15

**Added:**
- 🆕 `remove_rust` input to remove Rust toolchain (~1.5 GB on x86_64)
- 🧪 UseCase test for Rust/Cargo projects

**Changed:**
- 🔧 Upgrade `rmz` default version from 3.1.1 to 3.2.0
- 📊 Updated Size Savings table based on Run #210

**Fixed:**
- 🐛 Fix `remove_packages` validation rejecting single package names

**CI/CD Improvements:**
- 🧪 Add ARM64-specific package removal test
- 🔧 Change linter runner to `ubuntu-slim` for faster execution
```

### 7. Present to User

Show the proposed changelog entry and ask for confirmation before applying.

Include:
1. **Version bump recommendation** (major/minor/patch) with rationale
2. **Proposed changelog entry** in full markdown
3. **Files to update**: README.md (changelog section), VERSION file (if exists)
4. **Notable omissions**: Changes intentionally excluded and why
5. **Suggested commit message** for the changelog update itself

### 8. Apply Changes

After user confirmation:
1. Insert the new entry in `CHANGELOG.md` after the top header block, before the previous version entry
2. Update VERSION file if it exists
3. Suggest the git commands:

```bash
git add CHANGELOG.md VERSION
git commit -m "docs(changelog): add vX.Y.Z release notes"
```

## Edge Cases

- **No notable changes**: Report "No notable changes since vX.Y.Z" and suggest skipping the release
- **Only internal changes**: Report what was skipped and confirm with user
- **Multiple breaking changes**: Group under single MAJOR bump, list all in changelog
- **Pre-release (WIP)**: Use `### vX.Y.Z (Working in Progress)` header
- **First release**: Generate complete initial changelog from repository history
