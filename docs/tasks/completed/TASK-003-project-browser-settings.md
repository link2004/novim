# TASK-003 — Project browser settings

Updated: 2026-08-29
Task ID: `TASK-003`
Status: `ACCEPTED`
Delivery policy: `LIGHTWEIGHT`
Base branch: `main`
Task branch: `task/TASK-003-project-browser-settings`
Expected baseline: `794a7c6fe09abb335fb7c14273614a796b365631`
Pull request: `https://github.com/medonmez/novim-custom/pull/3`
Remote checks: `OPTIONAL / NOT_RUN`

## Outcome

Delivered a read-only project file browser in `novim-dev` with dot-prefixed
files and folders hidden by default, a persistent settings toggle, and safe
non-fatal handling for settings-write failures.

## Delivery record

- Implementation candidate: `1a8fb4ac687afa169b6e83c55afb8a48e863a848`.
- Local review: `APPROVED` after real-diff inspection and targeted local probes.
- Merge commit: `6a9be23522c43110dd4c4053f67ab22c8586d4b9`.
- Target branch contains change: `YES` (`origin/main`).

## Acceptance evidence

- `./tests/run_tests.sh`: 14/14 tests passed offline.
- Root and nested dotfiles/dot-folders are hidden by default and revealed by
  the settings toggle; directory previews apply the same filter and count only
  visible children while reporting hidden dot-items.
- Settings persist below the isolated `novim-dev` state path; missing,
  malformed, and invalid-type settings safely fall back to hidden-by-default.
- Failed settings writes retain the effective value, suppress the refresh
  callback, and render a visible non-fatal warning in the modal.
- Existing TASK-002 diff, divider, mouse-selection, and byte-invariance tests
  pass; launcher and installed-release version checks remain unchanged.
- No Git mutation, network, plugin dependency, or installed-release change was
  introduced.

Evidence is local review and remote merge evidence only; no hosted, production,
recovery, or customer-acceptance claim is made.
