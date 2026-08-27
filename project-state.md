# Project State

Updated: 2026-08-27
Repository: `novim-custom`
Lifecycle: `BOOTSTRAPPING`
Delivery policy: `LIGHTWEIGHT`
Current task: `TASK-001`
Base branch: `main`
Task branch: `task/TASK-001-dev-command`
Pull request: `NOT_OPEN`
Remote checks: `OPTIONAL / NOT_RUN`
Last accepted task: `NONE`
Last accepted commit: `NONE`
Last merged pull request: `NONE`

## Current truth

- The repository is a local clone of `link2004/novim` at upstream tag `v0.1.7`
  and commit `8e36d447ee9c73d29b75f3dfc50db9452a2addf1`.
- The clone lives at `/Users/mert/novim-custom`; its current remote is the
  upstream URL under the name `origin`. No GitHub fork has been created.
- The installed `novim` release remains independent and is not being edited.
- Workflow manifests and durable project records have been bootstrapped under
  `docs/` without removing or duplicating the upstream public documentation.
- `TASK-001` is the only actionable task. It plans the isolated `novim-dev`
  launcher; no implementation has been accepted yet.
- Product direction is now accepted for planning: a VS Code-like, two-pane,
  mouse-resizable, read-only Git diff workbench with a settings surface for
  dot-folder visibility and no plugin dependency.

## Active blockers

- None for `TASK-001`.
- Before `TASK-002` is issued, the diff baseline and settings persistence model
  must be fixed. Dot-folder default/allowlist semantics also need confirmation.

## Next orchestration action

Hand `TASK-001` to `$stateless-implementer` on its recorded branch. After its
handoff, inspect the real diff and run the task's smoke checks before any
feature task is issued.
