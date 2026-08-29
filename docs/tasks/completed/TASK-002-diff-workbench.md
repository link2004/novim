# TASK-002 — Read-only Git diff workbench

Updated: 2026-08-29
Task ID: `TASK-002`
Status: `ACCEPTED`
Delivery policy: `LIGHTWEIGHT`
Base branch: `main`
Task branch: `task/TASK-002-diff-workbench`
Expected baseline: `12327b78049e1348df858b589baf669ba451c090`
Pull request: `https://github.com/medonmez/novim-custom/pull/2`
Remote checks: `OPTIONAL / NOT_RUN`

## Outcome

Delivered a two-pane, read-only Git diff workbench in `novim-dev`. It compares
the working tree with `HEAD`, includes untracked files, safely preserves valid
Git paths, and supports native mouse selection and divider resizing.

## Delivery record

- Implementation candidate: `54ad217047eb07b75b08697129cde3c905418443`
- Local review: `APPROVED` after independent fixture and PTY validation.
- Merge commit: `794a7c6fe09abb335fb7c14273614a796b365631`
- Target branch contains change: `YES` (`origin/main`)

## Acceptance evidence

- `./tests/run_tests.sh`: 6/6 passed.
- Special-path fixture covered modified, deleted, renamed, staged-added,
  untracked, binary, quoted, tabbed, Unicode, and literal-arrow paths.
- Independent PTY validation confirmed left-pane click selection and native
  divider widths `26 -> 41`, `41 -> 24`, and `24 -> 15` at the minimum,
  without `E21`.
- Exact before/after `git status --porcelain=v1 -z -uall` and `git diff HEAD`
  invariance checks passed.
- `novim-dev --version` remained `0.1.7-dev`; installed `novim --version`
  remained `0.1.7`.
- No new runtime dependency, plugin manager, Git mutation action, or upstream
  site change was introduced.

Evidence is local review evidence only; no hosted, production, recovery, or
customer-acceptance claim is made.
