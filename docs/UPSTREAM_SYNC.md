# Safe Upstream Synchronization

This checkout uses `origin` for the personal fork and `upstream` for
`link2004/novim`. Synchronization is an explicit, user-mediated maintenance
operation. `bin/novim-dev` and `bin/novim-dev-package` never fetch, merge,
rebase, cherry-pick, or push.

## 1. Record a named baseline and fetch explicitly

Start from a clean checkout and record the exact commit before looking at
upstream changes. The fetch is the only network action in this procedure and
must be requested explicitly by the user.

```bash
git status --short --branch
git branch --show-current
BASELINE="$(git rev-parse --verify HEAD)"
git fetch --no-tags upstream main
UPSTREAM_MAIN="$(git rev-parse --verify upstream/main)"
printf 'BASELINE=%s\nUPSTREAM_MAIN=%s\n' "$BASELINE" "$UPSTREAM_MAIN"
git log --oneline --decorate "$BASELINE..$UPSTREAM_MAIN"
git diff --stat "$BASELINE..$UPSTREAM_MAIN"
```

If the working tree is not clean, stop and preserve the user's changes. Do
not use `git pull`, because it combines fetching and history integration before
the comparison checkpoint. Do not push to `upstream`.

## 2. Inspect changes on an isolated branch

Create a local recovery pointer and a review branch from the named baseline.
Use a task-specific branch name; never inspect or integrate directly on
`main`.

```bash
git branch "backup/pre-upstream-sync-YYYYMMDD" "$BASELINE"
git switch -c task/TASK-NNN-upstream-sync-review "$BASELINE"
git diff --name-status "$BASELINE..$UPSTREAM_MAIN"
git diff "$BASELINE..$UPSTREAM_MAIN" -- bin config VERSION LICENSE THIRD_PARTY_LICENSES.md
```

The review checkpoint must cover launcher identity and runtime isolation,
`config/nvim` and bundled assets, read-only Git behavior, package contents,
license/attribution files, and tests. Also inspect the full diff for changes
outside the selected scope. Upstream changes are candidates, not accepted
changes merely because they are newer.

## 3. Select changes only after review

For a selected commit, prefer a no-commit cherry-pick so the diff and tests can
be inspected before recording history:

```bash
git cherry-pick --no-commit <reviewed-upstream-commit>
git diff --cached --stat
./tests/run_tests.sh
bash -n bin/novim-dev bin/novim-dev-package tests/run_tests.sh
git diff --check
# Commit only after the review checkpoint passes.
git commit -m "sync: incorporate reviewed upstream change"
```

For a deliberate full synchronization, use a no-fast-forward, no-commit merge
on the isolated branch:

```bash
git merge --no-ff --no-commit "$UPSTREAM_MAIN"
git status --short
git diff --stat
./tests/run_tests.sh
git diff --check
# Commit only after conflicts, contracts, and validations are reviewed.
git commit -m "sync: merge reviewed upstream baseline"
```

Do not accept a merge solely because it is conflict-free. Recheck the
installed `novim` boundary, the `novim-dev` version and help output, isolated
runtime paths, no-default-network behavior, read-only Git invariants, package
manifest, and attribution notices.

## 4. Conflict handling and recovery

If a merge or cherry-pick conflicts, inspect the unmerged paths and decide
whether each one is in scope. If the change is not safe to resolve, return to
the pre-operation state without touching `main`:

```bash
git diff --name-only --diff-filter=U
git merge --abort                 # for an in-progress merge
git cherry-pick --abort           # for an in-progress cherry-pick
```

If a reviewed sync was already committed on the isolated branch, preserve the
recovery pointer and use a revert commit there:

```bash
git log --oneline --decorate -5
git revert -m 1 <sync-merge-commit>  # merge commit
# or: git revert <sync-commit>       # one selected commit
```

The named `backup/pre-upstream-sync-YYYYMMDD` pointer identifies the exact
pre-sync baseline for comparison and recovery. Do not use `reset --hard` as a
generic recovery command, and do not delete or rewrite user work. After the
isolated branch is reviewed and accepted through the repository workflow, its
changes may be delivered to `main` by the orchestrator's normal lightweight
path.

## Boundaries

- Fetching is explicit and limited to the `upstream` remote; normal launcher,
  packaging, and installation commands are offline.
- All inspection and integration happens on a named isolated branch.
- The installed `novim` command and `$HOME/.local/share/novim` are not sync
  targets; use the derivative package/install path for `novim-dev`.
- This runbook describes local repository evidence only, not a hosted,
  production, recovery, or customer-acceptance result.
