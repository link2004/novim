# Current Task

Updated: 2026-08-29
Task ID: `TASK-005`
Status: `CHANGES_REQUESTED`
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
- Status: `CHANGES_REQUESTED`
- Candidate commit: `fc4086be3ca6bad8b75189fdaa00dd02ba09bcf0` (handoff commit)
- Outcome summary: Delivered deterministic local regression-smoke layer for `novim-dev` launcher, two-pane workbench, source navigation, settings persistence, and read-only Git diff invariance.
- Files changed:
  - `tests/test_smoke.lua` — dedicated headless Neovim regression smoke test suite exercising startup paths, two-pane layout, divider constraints, source navigation, unsaved buffer preservation, settings persistence, malformed input recovery, write failures, and exact byte-for-byte Git read-only invariance.
  - `tests/run_smoke_tests.sh` — standalone end-to-end smoke test script with CLI flag verification, working directory independence, symlink path resolution, installed `novim` independence, fixture teardown guarantee, and nonzero exit on failure.
  - `tests/run_tests.sh` — updated test runner supporting full test suite execution (21 integration tests + 6 smoke tests) and `--smoke` / `-s` flag.
  - `docs/architecture.md` — documented local testing and regression smoke layer architecture and commands.
  - `docs/tasks/current-task.md` — recorded completed acceptance criteria and implementer handoff.
- Validation performed:
  - `./tests/run_smoke_tests.sh`: PASS (6/6 smoke tests, CLI flags, symlink/cwd resolution, zero fixture residue).
  - `./tests/run_tests.sh`: PASS (21/21 integration tests + 6/6 smoke tests, 0 failures).
  - `./tests/run_tests.sh --smoke`: PASS (delegates cleanly to smoke runner).
  - `bash -n bin/novim-dev tests/run_tests.sh tests/run_smoke_tests.sh`: PASS (clean syntax).
  - `./bin/novim-dev --version`: PASS (`novim-dev 0.1.7-dev (custom checkout)` / Neovim `v0.12.5`).
  - `/Users/mert/.local/bin/novim --version`: PASS (`novim 0.1.7` / Neovim `v0.12.5` untouched).
  - `git diff --check`: PASS (clean diff, no whitespace or formatting errors).
- Acceptance criterion evidence:
  1. Documented local smoke runner (`tests/run_smoke_tests.sh`, `tests/run_tests.sh --smoke`) runs against temporary fixtures and exits nonzero on error.
  2. Isolated runtime paths (`.dev-data`, `.dev-state`, `.dev-cache`, `config`) verified; external cwd and symlinked binary invocations succeed without touching `~/.local/share/novim`.
  3. Two-pane layout, min width constraints, view switching, source preview/editing handoff, settings toggles, and close flow verified without losing in-memory unsaved edits.
  4. Clean, modified, deleted, renamed, untracked, binary files verified for diff rendering and 100% byte-for-byte Git status and diff invariance.
  5. Dotfile filtering, persistent state file roundtrip, malformed JSON recovery, and write-failure resilience verified.
  6. Runner is completely offline and deterministic with guaranteed fixture cleanup and zero repository residue.
  7. Existing `./tests/run_tests.sh`, launcher syntax, version checks, and `git diff --check` all pass.
- Residual risks / known gaps: Local review found that the runner bypasses the
  launcher’s normal config-loading path and that its macOS fixture-residue scan
  only checks `/tmp`; see `docs/reviews/latest-review.md`. Local development
  validation only; no hosted or production claim is made.

## Review follow-up

- Local verdict: `CHANGES_REQUESTED` at candidate `fc4086be3ca6bad8b75189fdaa00dd02ba09bcf0`.
- Required changes: exercise the launcher’s default config/root resolution in
  the headless smoke path, including external/symlink invocation, and make
  fixture-residue verification use the actual run-owned temporary root rather
  than a hard-coded `/tmp` glob.
- Next action: return this same task branch to `$stateless-implementer`; do not
  open or merge a PR until a new handoff is ready.
