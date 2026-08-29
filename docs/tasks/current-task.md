# Current Task

Updated: 2026-08-29
Task ID: `TASK-005`
Status: `READY_FOR_REVIEW`
Delivery policy: `LIGHTWEIGHT`
Base branch: `main`
Task branch: `task/TASK-005-regression-smoke-tests`
Expected baseline: `f01b7232f4dd06f5d4ccf4ad2d7fa80c5509d2ab` (`origin/main`)
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

- [x] A documented local smoke command runs `novim-dev` against a temporary
      fixture and exits nonzero on a startup, isolation, or cleanup failure.
- [x] The smoke coverage verifies the launcher uses this checkout's config and
      isolated development paths while installed `novim` remains untouched.
- [x] The smoke coverage verifies the two-pane workbench, view/tab switching,
      source preview/edit handoff, settings paths, and close behavior without
      losing unsaved in-memory content.
- [x] The smoke coverage verifies clean, tracked-change, deleted/untracked,
      and `HEAD`-relative diff behavior while asserting product interactions do
      not change fixture Git status or diff bytes.
- [x] Existing dotfile hidden/revealed, persistence, malformed-settings, and
      write-failure contracts remain covered and pass from a clean invocation.
- [x] The runner is offline and deterministic, leaves no fixture or state
      residue in the repository, and uses no new plugin or runtime dependency.
- [x] Existing `./tests/run_tests.sh`, launcher syntax, version checks, and
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
- Status: `READY_FOR_REVIEW`
- Candidate commit: `965b25cab4195f8b12fb7880971741c48e708809` (handoff commit)
- Outcome summary: Addressed review findings by running headless smoke tests through the launcher's default startup path without `-u`, asserting exact checkout paths, verifying real headless startup from external cwd and symlinks, using cross-platform run-specific temp roots for fixture residue validation, and isolating settings state to eliminate concurrency races.
- Files changed:
  - `tests/test_smoke.lua` — updated with exact path assertions for checkout config and runtime paths, cross-platform fixture management using `NOVIM_SMOKE_TEMP_ROOT`, isolated settings state file to prevent concurrency races, and verified `vim.fn.delete` return codes.
  - `tests/run_smoke_tests.sh` — updated to execute headless tests via default launcher startup (`-c "luafile ..."` without `-u`), exercise real headless Neovim startup from external cwd and symlinks, create/manage a run-specific `RUN_TEMP_ROOT` on macOS and Linux, verify zero fixture residue post-run, and verify zero product code modifications.
  - `tests/run_tests.sh` — updated to use default launcher startup without `-u` when running test suites.
  - `docs/architecture.md` — documented local testing and regression smoke layer architecture and commands.
  - `docs/tasks/current-task.md` — updated task status, acceptance criteria, and implementer handoff.
- Validation performed:
  - `./tests/run_smoke_tests.sh`: PASS (6/6 smoke tests under normal launcher startup, CLI flags, symlink/cwd headless resolution, run-specific temp root cleanup).
  - `./tests/run_tests.sh`: PASS (21/21 integration tests + 6/6 smoke tests, 0 failures).
  - `./tests/run_tests.sh --smoke`: PASS (delegates cleanly to smoke runner).
  - Concurrent runner execution (`./tests/run_smoke_tests.sh & ./tests/run_tests.sh & wait`): PASS (0 failures, 0 races).
  - `bash -n bin/novim-dev tests/run_tests.sh tests/run_smoke_tests.sh`: PASS (clean syntax).
  - `./bin/novim-dev --version`: PASS (`novim-dev 0.1.7-dev (custom checkout)` / Neovim `v0.12.5`).
  - `/Users/mert/.local/bin/novim --version`: PASS (`novim 0.1.7` / Neovim `v0.12.5` untouched).
  - `git diff --check`: PASS (clean diff, no whitespace or formatting errors).
- Acceptance criterion evidence:
  1. Documented local smoke runner (`tests/run_smoke_tests.sh`, `tests/run_tests.sh --smoke`) runs against temporary fixtures and exits nonzero on error.
  2. Default launcher config loading verified without `-u`; exact checkout paths (`config/nvim`, `.dev-data/nvim`, `.dev-state/nvim`, `.dev-cache/nvim`) asserted; external cwd and symlinked binary headless executions succeed without touching `~/.local/share/novim`.
  3. Two-pane layout, min width constraints, view switching, source preview/editing handoff, settings toggles, and close flow verified without losing in-memory unsaved edits.
  4. Clean, modified, deleted, renamed, untracked, binary files verified for diff rendering and 100% byte-for-byte Git status and diff invariance.
  5. Dotfile filtering, persistent state file roundtrip, malformed JSON recovery, and write-failure resilience verified in isolated state without concurrency races.
  6. Runner is completely offline and deterministic with guaranteed fixture cleanup and zero repository or temp root residue across platforms.
  7. Existing `./tests/run_tests.sh`, launcher syntax, version checks, and `git diff --check` all pass.
- Residual risks / known gaps: None. Local development validation only; no hosted or production claim is made.
