# Protect the Active Runner Runtime

## Intent

Prevent `remove_folders` from deleting the Node.js runtime required by GitHub Actions itself. On affected hosted runners, the runtime under the runner's cached externals directory resolves to `/opt/runner-cache/externals`, so removing that cache breaks later JavaScript actions and post-job steps.

## Goals

- Preserve the active runner runtime even when a requested folder is its parent, such as `/opt/runner-cache` or `/opt`.
- Continue removing unrelated requested folders with both `rm` and `rmz`.
- Emit a clear warning for each skipped path.
- Remove `/opt/runner-cache` from the full and large cleanup test inputs and correct the maintenance documentation.

## Non-goals

- Do not prevent removal of `/opt/hostedtoolcache` or `/opt/actionarchivecache`.
- Do not block safe cleanup of runner installer archives or unrelated cache contents.
- Do not change the behavior of package removal or the dedicated cleanup functions.

## Constraints

- Use Bash and existing runner utilities; add no dependencies.
- Preserve parallel `rm` behavior and the existing `rmz` path.
- Apply the same filtering in testing and real-removal modes.
- Support the hosted-runner layout used before and after the runtime moved behind `/opt/runner-cache` links.

## Approaches

1. **Only change workflow inputs.** Smallest CI fix, but users could still delete the runtime through `remove_folders`.
2. **Delete only `/opt/runner-cache/*.tar.gz`.** Preserves the runtime in these workflows, but does not protect users who request the whole directory.
3. **Resolve and protect the active runtime in `remove_folders`.** Selected by the maintainer. This fixes the workflows and protects the public Action interface while leaving unrelated cleanup intact.

## Design

Before folder removal, resolve the runner's cached `externals/node*` paths from `RUNNER_HOME`, defaulting to `/home/runner/actions-runner` when that variable is unavailable. Canonicalize requested paths and skip a requested path when it contains a resolved runtime, is contained by it, or is the runtime itself. Perform filtering before dispatching parallel `rm` jobs and in the `rmz` loop. Print a GitHub Actions warning for every skipped path.

Add a local shell regression test using temporary runner and folder layouts. It will prove that the unprotected behavior would remove the runtime, that the protected behavior preserves it for parent and nested paths with both removal modes, and that unrelated paths remain eligible for removal. Run this test in CI alongside ShellCheck.

Update `AGENTS.md` to describe `/opt/runner-cache/externals` as protected runtime data rather than a safe cleanup candidate.

## Verification

- Run the regression test before implementation to reproduce the failure and after implementation to verify the fix.
- Run ShellCheck with the project's required options.
- Exercise `main.sh` in testing mode for both `rm` and `rmz`.
- Use the existing GitHub Actions matrix for hosted-runner integration verification after the change is pushed or dispatched.
