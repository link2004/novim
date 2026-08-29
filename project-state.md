# Project State

Updated: 2026-08-29
Repository: `novim-custom`
Lifecycle: `ACTIVE_DEVELOPMENT`
Delivery policy: `LIGHTWEIGHT`
Current task: `TASK-005`
Base branch: `main`
Task branch: `task/TASK-005-regression-smoke-tests`
Pull request: `NOT_OPEN`
Remote checks: `OPTIONAL / NOT_RUN`
Last accepted task: `TASK-004`
Last accepted commit: `cdb9140947f0fe4beb9a4748e599e8f769fb6aec`
Last merged pull request: `https://github.com/medonmez/novim-custom/pull/4`

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
- `TASK-004` was locally reviewed `APPROVED`, delivered through GitHub PR #4,
  and verified in merge commit `cdb9140947f0fe4beb9a4748e599e8f769fb6aec` on
  `origin/main`. The workbench opens regular project files in the right editor
  pane, preserves read-only directory and Git inspection, supports bidirectional
  Files/Git Diff navigation, and retains unsaved source buffers during preview
  navigation.
- `TASK-002` candidate `54ad217047eb07b75b08697129cde3c905418443`
  received local verdict `APPROVED`, was delivered through GitHub PR #2, and
  is present in merge commit `794a7c6fe09abb335fb7c14273614a796b365631` on
  `origin/main`. Native terminal mouse interaction was verified in an
  independent PTY, including bidirectional divider drag, minimum width
  behavior, and left-pane click selection without `E21`.

## Active blockers

- TASK-005 local review is `CHANGES_REQUESTED` at candidate
  `fc4086be3ca6bad8b75189fdaa00dd02ba09bcf0`. The same isolated branch remains
  active; no PR has been opened and no delivery claim is made. The smoke
  runner must exercise the launcher’s normal config/root path and must verify
  fixture cleanup under the host’s actual temporary-directory root.

## Next orchestration action

Return TASK-005 to `$stateless-implementer` on
`task/TASK-005-regression-smoke-tests`; address the latest review findings,
rerun validation, and stop at `READY_FOR_REVIEW` for another local review.
