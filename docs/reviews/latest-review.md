# Latest Review

Updated: 2026-08-29
Task ID: `TASK-003`
Local verdict: `CHANGES_REQUESTED`
Delivery policy: `LIGHTWEIGHT`
Baseline: `794a7c6fe09abb335fb7c14273614a796b365631` (`origin/main`)
Candidate: `c1fffc1`
Task branch: `task/TASK-003-project-browser-settings`
Pull request: `NOT_OPEN`
Remote checks: `OPTIONAL / NOT_RUN`
Merge status: `NOT_DELIVERED`
Target branch contains change: `NO`

## Review result

The core project tree, settings modal, persistent state path, and preserved
read-only diff workbench are present. The task remains active because two
scoped correctness gaps violate the task guardrails and require changes on the
same branch before delivery.

## Findings

### High — Directory previews bypass the hidden-dotfile rule

`config/nvim/lua/novim/browser.lua:188-227` renders every immediate child of a
selected directory without consulting `show_dotfiles`. With the default hidden
setting, selecting `src/` produces `.secret_module/` in the right-hand preview,
even though the same nested dot-folder is absent from the project tree. This
violates the requirement that dot-prefixed entries remain hidden at every
relevant tree level and leaks hidden names through a visible browser surface.

Required change: apply the same visibility rule to directory-preview children
and keep the summary/count consistent with the filtered contents. Add a test
covering hidden and revealed directory previews, including a nested dot-folder.

### Medium — Settings write failures are silently reported as successful toggles

`config/nvim/lua/novim/settings.lua:132-139` ignores the success/error result of
`M.set()`. In a write failure, `toggle_dotfiles()` returns the requested new
value even though the persisted value remains unchanged. The settings UI then
refreshes and invokes its workbench callback without displaying a non-fatal
error (`config/nvim/lua/novim/settings_ui.lua:93-100`). An independent probe
using a directory at the settings-file path observed `set_ok=false` followed by
`toggle_return=true loaded_after_toggle=false`.

Required change: propagate the persistence result through the toggle/UI path,
keep the displayed state aligned with the persisted setting, and show a clear
non-fatal error in the settings surface when saving fails. Add a regression test
for the failed-write path.

## Acceptance evidence

| Criterion | Result | Evidence |
|---|---|---|
| Fixture launch shows regular project files/directories | PASS | `./tests/run_tests.sh` passed the project-browser fixture checks. |
| Dot-prefixed entries hidden by default at nested levels | PARTIAL | `browser.get_tree(..., false)` and the left pane filter pass; the directory-preview bypass is a blocking gap. |
| Reachable, unambiguous settings toggle | PASS | Independent PTY launch showed Project Browser, `s` opened the modal, and the modal displayed OFF/ON state. |
| Toggle reveals/hides normal and nested dot entries | PASS | Automated toggle test passed for root, nested files, and nested dot-folders. |
| Fresh-process persistence | PASS | Two separate headless Neovim processes using a temporary isolated XDG state root restored `show_dotfiles=true`. |
| Missing/malformed settings fallback | PASS | Automated missing, malformed, and invalid-type cases passed without crashing. |
| TASK-002 diff/mouse/read-only invariance | PASS | Regression suite passed divider, mouse-selection, diff, and byte-invariance checks. |
| No mutation, network, dependency, or installed-release change | PASS | Candidate source adds no network/mutation path; shell checks, versions, and scoped diff inspection passed. |

## Validation performed

- `./tests/run_tests.sh`: passed, `13 total, 13 passed, 0 failed`.
- `bash -n bin/novim-dev tests/run_tests.sh`: passed.
- `git diff --check 794a7c6...HEAD`: passed.
- `./bin/novim-dev --version`: passed, `0.1.7-dev` / Neovim `0.12.5`.
- `/Users/mert/.local/bin/novim --version`: passed, installed `novim 0.1.7`.
- Independent PTY launch: Project Browser opened by default; `s` opened
  Settings; `t` toggled ON; `q` closed the modal; and the workbench exited
  cleanly.
- Independent fresh-process persistence probe passed with an isolated
  temporary XDG state root.
- Independent directory-preview probe reproduced hidden-name leakage for
  `.secret_module/`.
- Independent write-failure probe reproduced the false successful toggle.
- Candidate diff, branch, remotes, and ignored runtime state were inspected;
  no unrelated source files or untracked product files were found.

## Delivery decision

`CHANGES_REQUESTED`. Do not open or merge a PR for `c1fffc1`. No hosted,
production, recovery, or customer-acceptance claim is made by this local
review.

## Next action

Return TASK-003 to `$stateless-implementer` on the same branch. Address both
findings, add the two regression cases, rerun the required validation, and
produce a new local handoff for review.
