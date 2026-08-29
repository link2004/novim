# TASK-004 — Source navigation

Updated: 2026-08-29
Task ID: `TASK-004`
Status: `ACCEPTED`
Delivery policy: `LIGHTWEIGHT`
Base branch: `main`
Task branch: `task/TASK-004-source-navigation`
Expected baseline: `6a9be23522c43110dd4c4053f67ab22c8586d4b9`
Pull request: `https://github.com/medonmez/novim-custom/pull/4`
Remote checks: `OPTIONAL / NOT_RUN`

## Outcome

The novim-dev workbench now opens selected regular project files in the right
Neovim editing pane, preserves read-only directory and Git previews, and
supports explicit bidirectional navigation between Files and Git Diff without
losing the project root, dotfile setting, two-pane layout, or unsaved source
buffers during preview navigation.

## Delivery record

- Implementation candidate: `2449369d35be78228116b98ef539684f25ae9de2`.
- Local review: `APPROVED` after real-diff inspection and targeted local probes.
- Review record: `d49f5c93c8a0fa9fd04a1eb2d115fca4eb7a6606`.
- Merge commit: `cdb9140947f0fe4beb9a4748e599e8f769fb6aec`.
- Target branch contains change: `YES` (`origin/main`).

## Acceptance evidence

- `./tests/run_tests.sh`: 21/21 passed, including regular-file opening,
  directory inspection, view switching, diff rendering, unsaved-buffer
  preservation, settings regressions, mouse behavior, and Git invariance.
- `./bin/novim-dev --version`: `0.1.7-dev` / Neovim `v0.12.5`.
- Installed `/Users/mert/.local/bin/novim --version`: `0.1.7` unchanged.
- `bash -n bin/novim-dev tests/run_tests.sh` and `git diff --check`: passed.
- An additional headless probe from an existing file session confirmed that an
  unsaved source buffer retains its content and `modified=true` state after the
  workbench tab closes, while the original editor tab remains.
- No Git mutation, network call, plugin dependency, or installed-release
  modification was introduced; fixture Git status and diff remained byte
  identical through the navigation cycle.

Evidence is local review and remote merge evidence only; no hosted,
production, recovery, or customer-acceptance claim is made.
