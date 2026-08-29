# Project State

Updated: 2026-08-29
Repository: `novim-custom`
Lifecycle: `ACTIVE_DEVELOPMENT`
Delivery policy: `LIGHTWEIGHT`
Current task: `TASK-004`
Base branch: `main`
Task branch: `task/TASK-004-source-navigation`
Pull request: `NOT_OPEN`
Remote checks: `OPTIONAL / NOT_RUN`
Last accepted task: `TASK-003`
Last accepted commit: `6a9be23522c43110dd4c4053f67ab22c8586d4b9`
Last merged pull request: `https://github.com/medonmez/novim-custom/pull/3`

## Current truth

- The repository is a local clone of `link2004/novim` at upstream tag `v0.1.7`
  and commit `8e36d447ee9c73d29b75f3dfc50db9452a2addf1`.
- The clone lives at `/Users/mert/novim-custom`; `origin` points to the
  personal fork `medonmez/novim-custom` and `upstream` points to the official
  `link2004/novim` repository.
- The installed `novim` release remains independent and is not being edited.
- Workflow manifests and durable project records have been bootstrapped under
  `docs/` without removing or duplicating the upstream public documentation.
- `TASK-001` was locally reviewed (`APPROVED` at candidate `b8512b6`) and
  delivered through GitHub PR #1. Merge commit
  `12327b78049e1348df858b589baf669ba451c090` is present on `origin/main`; all
  7 acceptance criteria passed local validation.
- Product direction is now accepted for planning: a VS Code-like, two-pane,
  mouse-resizable, read-only Git diff workbench with a settings surface for
  dot-folder visibility and no plugin dependency.
- `TASK-003` was locally reviewed `APPROVED`, delivered through GitHub PR #3,
  and verified in merge commit `6a9be23522c43110dd4c4053f67ab22c8586d4b9` on
  `origin/main`. The project browser hides dot-prefixed entries by default,
  persists the visibility setting under isolated state, filters directory
  previews consistently, and surfaces settings-write failures.
- `TASK-002` candidate `54ad217047eb07b75b08697129cde3c905418443`
  received local verdict `APPROVED`, was delivered through GitHub PR #2, and
  is present in merge commit `794a7c6fe09abb335fb7c14273614a796b365631` on
  `origin/main`. Native terminal mouse interaction was verified in an
  independent PTY, including bidirectional divider drag, minimum width
  behavior, and left-pane click selection without `E21`.

## Active blockers

- No active blocker. TASK-004 is planned on the new isolated branch
  `task/TASK-004-source-navigation` from the verified TASK-003 merge baseline.

## Next orchestration action

Implement TASK-004 on `task/TASK-004-source-navigation`, preserving the
accepted TASK-002 and TASK-003 read-only, isolated-runtime contracts.
