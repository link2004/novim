# Latest Review

Updated: 2026-08-29
Task ID: `TASK-002`
Local verdict: `CHANGES_REQUESTED`
Delivery policy: `LIGHTWEIGHT`
Baseline: `12327b78049e1348df858b589baf669ba451c090` (`origin/main`)
Candidate: `3a44c203d55537c6bdbd41c73d99678ab824fd2a`
Task branch: `task/TASK-002-diff-workbench`
Pull request: `NOT_OPEN`
Remote checks: `OPTIONAL / NOT_RUN`
Merge status: `NOT_DELIVERED`
Target branch contains change: `NO`

## Findings

### HIGH — Real mouse interaction is still broken and the regression test masks it

`config/nvim/lua/novim/workbench.lua:663-665` maps `<LeftMouse>` in the
readonly left-pane buffer and runs `normal! <LeftMouse>`. In an independent
interactive PTY fixture, a mouse press at the divider produced
`E21: Cannot make changes, 'modifiable' is off`; the divider did not resize.
The same mapping also prevents ordinary left-pane mouse selection from being a
clean interaction.

`tests/test_workbench.lua:243-266` sends mouse input, but when the event does
not change the width it calls `nvim_win_set_width` directly. An independent
headless mouse-only probe measured `before=26 after=26`, so the suite's 5/5
result does not prove that a real drag was handled.

Preserve native divider mouse handling and make left-pane mouse interaction
work without attempting to modify a readonly buffer. Replace the fallback
that converts an unhandled event into a pass, and record a real PTY/terminal
drag in both directions with minimum-width checks. Keep the exact Git-state
invariance assertions.

## Acceptance evidence

| Criterion | Result | Evidence |
|---|---|---|
| Offline fixture launch | PASS | `./tests/run_tests.sh` completed under the bundled checkout configuration without a plugin installation or hosted service. |
| Changed-file list includes tracked and untracked files | PASS | Special-path regression passes; an independent PTY fixture listed modified, deleted, renamed, staged-added, and untracked entries. |
| Tracked diff against `HEAD` shows additions/deletions | PASS | Independent fixture selected `tracked.txt` and rendered `-base 2`, `+MODIFIED`, and `+added` from `git diff HEAD`. |
| Untracked file shows readable all-additions view | PASS | Special-path regression rendered arrow, quote, tab, and Unicode filenames and their content without staging. |
| Mouse divider resizes both directions and respects minimum widths | FAIL | Real PTY mouse input did not resize; the left-pane mapping raised `E21`. The automated test uses a direct-width fallback after failed input. |
| No Git mutation and exact status/diff invariance | PASS | Suite compares byte-for-byte before/after `git status --porcelain=v1 -z -uall` and `git diff HEAD`; product Git calls are read-only by source inspection. |
| Launcher isolation and installed `novim` unchanged | PASS | `./bin/novim-dev --version` reports `0.1.7-dev`; installed `/Users/mert/.local/bin/novim --version` reports `0.1.7`; isolated `.dev-*` paths remain in use. |
| No new dependency or unrelated upstream site change | PASS | Complete diff adds no plugin/dependency and does not modify upstream site assets. |

## Validation performed

- `./tests/run_tests.sh`: passed, `5 total, 5 passed, 0 failed`.
- `bash -n bin/novim-dev tests/run_tests.sh`: passed.
- `git diff --check origin/main...HEAD`: passed.
- `./bin/novim-dev --version`: passed, `0.1.7-dev` / Neovim `0.12.5`.
- `/Users/mert/.local/bin/novim --version`: passed, installed `novim 0.1.7`.
- Independent headless mouse-only probe: failed to resize, `before=26 after=26`.
- Independent interactive PTY mouse probe: left-pane `<LeftMouse>` raised
  `E21: Cannot make changes, 'modifiable' is off` and did not resize the
  divider.
- Independent tracked-diff fixture: rendered expected additions/deletions.
- Complete candidate diff and repository status inspected; no untracked
  product files or unrelated source changes found. `.dev-state/` is ignored
  runtime state.

## Required changes or blocker

Return the same `TASK-002` branch to `$stateless-implementer`. Fix the HIGH
mouse interaction finding, add non-masking interaction evidence, rerun the
full local validation, and stop again at `READY_FOR_REVIEW` with a new
candidate commit. Do not open a PR or merge this candidate.

## Next action

Run `$stateless-implementer` on `task/TASK-002-diff-workbench` to correct the
mouse handling and return a new local handoff.
