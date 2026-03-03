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

## Terminal & CLI Gotchas

These are hard-learned lessons — follow them strictly:

### gh CLI Pager

`gh` commands like `release list` open a pager by default. **Always** use one of these approaches:
- Use `--json ... -q` for structured output: `gh release list --json tagName -q '.[].tagName'`
- Set `GH_PAGER=''` environment variable

### Git Tag Signing

If the user has `tag.gpgSign=true` in their git config, `git tag <name> <commit>` will fail with `fatal: no tag message?`. **Always** use annotated tags with `-m`:

```bash
git tag v3.2.0 f63fea6 -m "v3.2.0"
```

### Command Chaining

**Do NOT chain multiple long commands with `&&`** in a single terminal call. Run each command separately to:
- See individual errors clearly
- Avoid terminal pager/buffer issues
- Get precise feedback on which step failed

### gh release create + --target

`gh release create` with `--target <SHA>` fails if the tag doesn't already exist and the target is a commit SHA. **Always create and push the tag first**, then create the release using that tag.

## Workflow

### 1. Detect Current State

Run these as **separate commands**:

```bash
# Verify gh is authenticated
gh auth status

# Get the latest semantic version tag (exclude major-only tags like v3)
git tag --sort=-v:refname | grep -E '^v[0-9]+\.[0-9]+\.[0-9]+$' | head -1

# Check current HEAD commit
git --no-pager log --oneline -1
```

### 2. Confirm the Changelog is Ready

Before creating any release, verify that `CHANGELOG.md` has an entry for the target version. If the `[Unreleased]` section has content but no version entry exists, invoke the **changelog-maintainer** skill first to finalize the entry.

### 3. Extract Release Notes from CHANGELOG

**Always prefer CHANGELOG content over `--generate-notes`.** The `--generate-notes` flag produces raw commit lists that are ugly and unhelpful for users.

Extract the relevant version section from `CHANGELOG.md`:

```bash
# Extract notes for a specific version (between its header and the next --- or ## header)
# Use sed/awk to extract the section, or read the file and copy the section manually
```

When implementing, read `CHANGELOG.md`, find the section for the target version (between `## [vX.Y.Z]` and the next `---` or `## [` line), and pass that content as `--notes`.

**Fallback only**: If no CHANGELOG entry exists and the user confirms it's OK, use `--generate-notes --notes-start-tag <previous_tag>` as a last resort.

### 4. Create Tag and Release (Correct Order)

**The tag MUST exist before creating the release.** Follow this exact sequence:

```bash
NEW_VERSION="v3.2.0"        # confirmed version
TARGET_COMMIT="f63fea6"      # commit to tag (HEAD or specific SHA)

# Step 1: Create the annotated tag locally (always use -m to avoid gpg issues)
git tag "${NEW_VERSION}" "${TARGET_COMMIT}" -m "${NEW_VERSION}"

# Step 2: Push the tag to remote
git push origin "${NEW_VERSION}"

# Step 3: Create the release using the tag (with CHANGELOG notes)
gh release create "${NEW_VERSION}" \
  --title "${NEW_VERSION}" \
  --notes "<paste extracted CHANGELOG section here>"
```

If the tag targets HEAD, omit `TARGET_COMMIT`:
```bash
git tag "${NEW_VERSION}" -m "${NEW_VERSION}"
```

### 5. Update the Major Version Alias

GitHub Actions users pin to `vMAJOR` (e.g., `uses: endersonmenezes/free-disk-space@v3`). After creating the new release, the major tag must be moved to point to the same commit.

**This requires deleting and recreating both the release and the tag for the major version.**

Run each command **separately** (do not chain):

```bash
MAJOR_VERSION="v3"  # extract from NEW_VERSION

# Step 5a: Delete the existing major release (if it exists)
gh release delete "${MAJOR_VERSION}" --yes || true

# Step 5b: Delete the existing major tag from remote
git push origin --delete "${MAJOR_VERSION}" || true

# Step 5c: Delete the local major tag
git tag -d "${MAJOR_VERSION}" || true

# Step 5d: Create the new major tag pointing to the same commit as NEW_VERSION
git tag "${MAJOR_VERSION}" -m "${MAJOR_VERSION}"

# Step 5e: Push the new major tag
git push origin "${MAJOR_VERSION}"

# Step 5f: Detect the repo slug and create the new major release
REPO_SLUG=$(gh repo view --json nameWithOwner -q '.nameWithOwner')

gh release create "${MAJOR_VERSION}" \
  --title "${MAJOR_VERSION}" \
  --notes "Alias to [${NEW_VERSION}](https://github.com/${REPO_SLUG}/releases/tag/${NEW_VERSION})"
```

### 6. Verify

Run these as **separate commands**:

```bash
# Check each tag points to the expected commit
git --no-pager log --oneline -1 "${NEW_VERSION}"
git --no-pager log --oneline -1 "${MAJOR_VERSION}"

# Both must show the SAME commit SHA
```

## Complete Example (v3.1.0 → v3.2.0)

Each line below is a **separate terminal command** (do not chain):

```bash
# 1. Create and push the tag
git tag v3.2.0 -m "v3.2.0"
git push origin v3.2.0

# 2. Create the release with CHANGELOG notes
gh release create v3.2.0 --title "v3.2.0" --notes "<changelog section>"

# 3. Delete old major alias release
gh release delete v3 --yes || true

# 4. Delete old major tag (remote then local)
git push origin --delete v3 || true
git tag -d v3 || true

# 5. Recreate major alias
git tag v3 -m "v3"
git push origin v3
REPO_SLUG=$(gh repo view --json nameWithOwner -q '.nameWithOwner')
gh release create v3 --title "v3" --notes "Alias to [v3.2.0](https://github.com/${REPO_SLUG}/releases/tag/v3.2.0)"

# 6. Verify
git --no-pager log --oneline -1 v3.2.0
git --no-pager log --oneline -1 v3
```

## Error Handling

| Error | Cause | Fix |
|-------|-------|-----|
| `gh: Not logged in` | gh CLI not authenticated | Run `gh auth login` first |
| `release not found` on delete | Major release doesn't exist yet (first release) | Safe to ignore (`\|\| true`) |
| `tag not found` on delete | Major tag doesn't exist yet | Safe to ignore (`\|\| true`) |
| `already exists` on create | Tag/release wasn't deleted properly | Delete manually, retry |
| `permission denied` | Missing repo permissions | User must have write access |
| `fatal: no tag message?` | gpg signing enabled without `-m` | Always use `git tag <name> -m "<name>"` |
| `tag_name is not a valid tag` | Tag doesn't exist on remote when creating release | Create and push tag BEFORE `gh release create` |
| Pager opens / command hangs | `gh` pager not disabled | Use `--json -q` or `GH_PAGER=''` |

## Rules

- **NEVER** create a release without confirming the version with the user (unless explicitly provided)
- **ALWAYS** verify `gh auth status` before running any `gh` command
- **ALWAYS** create and push the tag BEFORE running `gh release create`
- **ALWAYS** use annotated tags with `-m` flag to avoid gpg signing failures
- **ALWAYS** use CHANGELOG content for release notes — never `--generate-notes` unless no CHANGELOG entry exists
- **ALWAYS** run commands separately — never chain with `&&` in terminal calls
- **ALWAYS** use `--no-pager` for git commands and `--json -q` for gh commands
- **ALWAYS** delete the major release BEFORE deleting the major tag
- **ALWAYS** create the major tag BEFORE creating the major release  
- **NEVER** use `--force` on tag push — delete and recreate instead
- The major release notes are always: `Alias to [<NEW_VERSION>](https://github.com/<OWNER>/<REPO>/releases/tag/<NEW_VERSION>)` (with link to the release)
