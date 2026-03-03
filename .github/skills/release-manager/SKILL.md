# Skill: Release Manager

## Description

Manages the full release cycle for the Free Disk Space GitHub Action using `gh` CLI. Creates a new semantic version release and updates the major version alias tag so users pinning to `vMAJOR` always get the latest.

## Prerequisites

- `gh` CLI installed and authenticated (`gh auth status` must succeed)
- User must have push + release permissions on the repository
- Working directory must be the repository root

## When to Use

Trigger this skill when:
- User asks to "create a release", "publish a release", or "cut a release"
- User mentions "update major tag", "bump version", or "new version"
- User wants to "prepare vX.Y.Z for release"

## IMPORTANT: Always Confirm the Target Version

Before proceeding, **always confirm the new version with the user** unless they explicitly stated it. Use the `vscode/askQuestions` tool:

```json
{
  "questions": [
    {
      "header": "Release Version",
      "question": "Current latest tag is `<detected_tag>`. What version should the new release be?",
      "options": [
        { "label": "<next_patch>", "description": "Patch bump" },
        { "label": "<next_minor>", "description": "Minor bump" },
        { "label": "<next_major>", "description": "Major bump" }
      ],
      "allowFreeformInput": true
    }
  ]
}
```

If the user already specified the version (e.g., "release v3.2.0"), skip the prompt and proceed.

## Workflow

### 1. Detect Current State

```bash
# Verify gh is authenticated
gh auth status

# Get the latest semantic version tag (exclude major-only tags like v3)
git tag --sort=-v:refname | grep -E '^v[0-9]+\.[0-9]+\.[0-9]+$' | head -1

# Get the current major version
# e.g., v3.1.0 → MAJOR=3
```

### 2. Confirm the Changelog is Ready

Before creating any release, verify that `CHANGELOG.md` has an entry for the target version. If the `[Unreleased]` section has content but no version entry exists, invoke the **changelog-maintainer** skill first to finalize the entry.

### 3. Create the New Semantic Version Release

```bash
# Set variables
NEW_VERSION="v3.2.0"  # example — use the confirmed version

# Create the release (this also creates the tag)
gh release create "${NEW_VERSION}" \
  --title "${NEW_VERSION}" \
  --notes-file - <<< "$(extract_changelog_notes)"  
  --target main
```

**For the release notes:** Extract the relevant section from `CHANGELOG.md` for this version. If no changelog entry exists, use `--generate-notes` to auto-generate from commits.

Practical approach:
```bash
# Option A: Use changelog entry (preferred)
# Extract the section between the version header and the next header
# and pass it as release notes

# Option B: Auto-generate from commits (fallback)
gh release create "${NEW_VERSION}" \
  --title "${NEW_VERSION}" \
  --generate-notes \
  --target main
```

### 4. Update the Major Version Alias

GitHub Actions users pin to `vMAJOR` (e.g., `uses: endersonmenezes/free-disk-space@v3`). After creating the new release, the major tag must be moved to point to the same commit.

**This requires deleting and recreating both the release and the tag for the major version.**

```bash
MAJOR_VERSION="v3"  # extract from NEW_VERSION

# Step 4a: Delete the existing major release (if it exists)
gh release delete "${MAJOR_VERSION}" --yes || true

# Step 4b: Delete the existing major tag (remote + local)
git push origin --delete "${MAJOR_VERSION}" || true
git tag -d "${MAJOR_VERSION}" || true

# Step 4c: Create the new major tag pointing to HEAD
git tag "${MAJOR_VERSION}"
git push origin "${MAJOR_VERSION}"

# Step 4d: Detect the repo slug and create the new major release
REPO_SLUG=$(gh repo view --json nameWithOwner -q '.nameWithOwner')

gh release create "${MAJOR_VERSION}" \
  --title "${MAJOR_VERSION}" \
  --notes "Alias to [${NEW_VERSION}](https://github.com/${REPO_SLUG}/releases/tag/${NEW_VERSION})" \
  --target main
```

### 5. Verify

```bash
# List the latest releases to confirm
gh release list --limit 5

# Verify tags point to the same commit
git log --oneline -1 "${NEW_VERSION}"
git log --oneline -1 "${MAJOR_VERSION}"
```

Both tags must resolve to the same commit SHA.

## Complete Example (v3.1.0 → v3.2.0)

```bash
# 1. Create the new release
gh release create v3.2.0 --title "v3.2.0" --generate-notes --target main

# 2. Delete old major alias
gh release delete v3 --yes
git push origin --delete v3
git tag -d v3

# 3. Recreate major alias
git tag v3
git push origin v3
REPO_SLUG=$(gh repo view --json nameWithOwner -q '.nameWithOwner')
gh release create v3 --title "v3" --notes "Alias to [v3.2.0](https://github.com/${REPO_SLUG}/releases/tag/v3.2.0)" --target main

# 4. Verify
gh release list --limit 5
```

## Error Handling

| Error | Cause | Fix |
|-------|-------|-----|
| `gh: Not logged in` | gh CLI not authenticated | Run `gh auth login` first |
| `release not found` on delete | Major release doesn't exist yet (first release) | Safe to ignore (`\|\| true`) |
| `tag not found` on delete | Major tag doesn't exist yet | Safe to ignore (`\|\| true`) |
| `already exists` on create | Tag/release wasn't deleted properly | Delete manually, retry |
| `permission denied` | Missing repo permissions | User must have write access |

## Rules

- **NEVER** create a release without confirming the version with the user (unless explicitly provided)
- **ALWAYS** verify `gh auth status` before running any `gh` command
- **ALWAYS** delete the major release BEFORE deleting the major tag
- **ALWAYS** create the major tag BEFORE creating the major release  
- **NEVER** use `--force` on tag push — delete and recreate instead
- The major release notes are always: `Alias to [<NEW_VERSION>](https://github.com/<OWNER>/<REPO>/releases/tag/<NEW_VERSION>)` (with link to the release)
