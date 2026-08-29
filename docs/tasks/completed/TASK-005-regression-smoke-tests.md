# TASK-005 — Regression smoke tests

Updated: 2026-08-29
Task ID: `TASK-005`
Status: `ACCEPTED`
Delivery policy: `LIGHTWEIGHT`
Base branch: `main`
Task branch: `task/TASK-005-regression-smoke-tests`
Expected baseline: `f01b7232f4dd06f5d4ccf4ad2d7fa80c5509d2ab`
Pull request: `https://github.com/medonmez/novim-custom/pull/6`
Remote checks: `OPTIONAL / NOT_RUN`

## Outcome

Added a deterministic local regression-smoke layer for the accepted
`novim-dev` launcher and read-only workbench. The suite covers normal launcher
startup, isolated runtime paths, external and symlink invocation, workbench
navigation, settings persistence and error handling, read-only Git diff
invariance, and cross-platform fixture cleanup.

## Delivery record

- Implementation candidate: `965b25cab4195f8b12fb7880971741c48e708809`.
- Initial review found launcher-boundary and macOS cleanup gaps; the same task
  branch addressed both findings and returned a revised handoff.
- Revised local review: `APPROVED`.
- Review record: `c237cbd69698f6932eb19d42c888430bfbb93028`.
- Merge commit: `cd938e2ce0ef9e792b2979cd325e614a65d42590`.
- Target branch contains change: `YES` (`origin/main`).

## Acceptance evidence

- `./tests/run_smoke_tests.sh`: 6/6 passed through normal launcher startup,
  including exact checkout paths, external cwd and symlink probes, and zero
  residue in the run-specific temporary root.
- `./tests/run_tests.sh`: 21/21 integration tests and 6/6 smoke tests passed.
- `./tests/run_tests.sh --smoke`: passed.
- Concurrent smoke/full-runner execution passed without the prior shared-state
  race.
- `bash -n bin/novim-dev tests/run_tests.sh tests/run_smoke_tests.sh` and
  `git diff --check`: passed.
- Development `novim-dev --version` reports `0.1.7-dev` with Neovim `v0.12.5`;
  installed `/Users/mert/.local/bin/novim --version` remains `0.1.7`.
- The smoke fixtures cover two-pane layout, minimum widths, Files/Git Diff
  switching, source editing and unsaved-buffer preservation, dotfile
  filtering, malformed settings, write failures, clean/modified/deleted/
  renamed/untracked/binary Git states, non-Git handling, and exact status and
  `git diff HEAD` byte invariance.
- No network action, Git mutation path, new runtime dependency, or installed
  release modification was introduced.

Evidence is local review and remote merge evidence only; no hosted, production,
recovery, or customer-acceptance claim is made.
