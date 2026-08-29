# Current Task

Updated: 2026-08-29
Task ID: `TASK-005`
Status: `PLANNED`
Delivery policy: `LIGHTWEIGHT`
Base branch: `main`
Task branch: `task/TASK-005-regression-smoke-tests`
Expected baseline: `cdb9140947f0fe4beb9a4748e599e8f769fb6aec` (`origin/main`)
Pull request: `NOT_OPEN`
Remote checks: `OPTIONAL / NOT_RUN`

## Outcome

Add a deterministic local regression-smoke layer for the accepted novim-dev
launcher and workbench behavior, so future changes can verify startup,
two-pane layout, settings persistence, and Git diff rendering without relying
on hosted services or a plugin manager.

## Context

TASK-001 established the isolated `novim-dev` command. TASK-002 delivered the
read-only Git diff workbench, TASK-003 added the persistent dotfile setting,
and TASK-004 added source-file opening and Files/Git Diff navigation. The next
slice is a small, repeatable regression entry point over those accepted local
contracts.

## In scope

- Add or organize local smoke checks for `novim-dev` version/help behavior,
  checkout-root resolution, and isolated runtime paths.
- Exercise workbench startup and close behavior, two-pane layout, active view
  rendering, minimum widths, and native divider interaction in a temporary
  fixture where practical.
- Exercise settings default, persistence, malformed-input fallback, and
  write-failure behavior through the isolated state path.
- Exercise tracked, untracked, and clean Git diff rendering plus exact
  status/diff invariance after read-only workbench interactions.
- Keep the smoke runner deterministic, self-cleaning, offline, and usable from
  a fresh checkout with the repository's existing Neovim dependencies.

## Out of scope

- Changing accepted launcher, workbench, browser, settings, or Git semantics
  except for a narrowly evidenced testability fix required by a failing smoke
  check.
- Hosted CI, production/release packaging, external services, network calls,
  plugin installation, or customer data.
- Git stage, unstage, commit, push, pull, merge, rebase, reset, checkout,
  restore, discard, or any repository mutation by the product under test.
- Replacing the existing focused tests with a new test framework or adding
  unrelated product features.

## Acceptance criteria

- [ ] A documented local smoke command runs `novim-dev` against a temporary
      fixture and exits nonzero on a startup, isolation, or cleanup failure.
- [ ] The smoke coverage verifies the launcher uses this checkout's config and
      isolated development paths while installed `novim` remains untouched.
- [ ] The smoke coverage verifies the two-pane workbench, view/tab switching,
      source preview/edit handoff, settings paths, and close behavior without
      losing unsaved in-memory content.
- [ ] The smoke coverage verifies clean, tracked-change, deleted/untracked,
      and `HEAD`-relative diff behavior while asserting product interactions do
      not change fixture Git status or diff bytes.
- [ ] Existing dotfile hidden/revealed, persistence, malformed-settings, and
      write-failure contracts remain covered and pass from a clean invocation.
- [ ] The runner is offline and deterministic, leaves no fixture or state
      residue in the repository, and uses no new plugin or runtime dependency.
- [ ] Existing `./tests/run_tests.sh`, launcher syntax, version checks, and
      `git diff --check` remain passing.

## Decision guardrails

- Keep the smoke layer local and additive; preserve the current test entry
  point unless a compatibility-preserving wrapper is necessary.
- Fixture setup may create and commit temporary Git fixtures for test purposes,
  but the product path under test must remain read-only and all fixtures must
  be removed on success and failure.
- Keep development state under the existing isolated `.dev-*` paths and never
  write credentials, source snapshots, or private data to repository docs.
- Do not turn local smoke results into hosted, production, recovery, or
  customer-acceptance evidence.

## Relevant areas

- `bin/novim-dev` — isolated launcher behavior and CLI smoke entry point.
- `tests/run_tests.sh` and `tests/test_workbench.lua` — existing local test
  runner and workbench fixture coverage.
- `config/nvim/init.lua` and `config/nvim/lua/novim/` — runtime contracts under
  test; product changes are not expected by default.
- `.dev-data/`, `.dev-state/`, `.dev-cache/` — isolated runtime paths that must
  not leak into the repository.

## Required validation

- Run the new smoke command from the repository root and from an external cwd
  or symlinked launcher path where the existing contract requires it.
- Run `./tests/run_tests.sh`, `bash -n bin/novim-dev tests/run_tests.sh`, both
  development and installed version checks, and `git diff --check`.
- Inspect the fixture cleanup, process exit status, generated files, and
  `git status --short --branch` after the run.
- Keep all evidence local and separate from hosted, production, recovery, and
  customer-acceptance claims.

## Blockers and dependencies

- No product decision is open for this bounded regression slice.
- Dependencies: TASK-001 through TASK-004 are accepted on `origin/main` at
  `cdb9140947f0fe4beb9a4748e599e8f769fb6aec`.
- No remote or hosted service is required for implementation or validation.

## Implementation handoff

Not started. Use `$stateless-implementer` on the recorded isolated branch and
stop at `READY_FOR_REVIEW` with a local validation summary.
