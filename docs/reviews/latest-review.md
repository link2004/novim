# Latest Review

Updated: 2026-08-29
Task ID: `TASK-002`
Local verdict: `CHANGES_REQUESTED`
Delivery policy: `LIGHTWEIGHT`
Baseline: `12327b78049e1348df858b589baf669ba451c090` (`origin/main`)
Candidate: `6d6edd81bed671bce81aeca259214cdcf31f2ac9`
Task branch: `task/TASK-002-diff-workbench`
Pull request: `NOT_OPEN`
Remote checks: `OPTIONAL / NOT_RUN`
Merge status: `NOT_DELIVERED`
Target branch contains change: `NO`

## Findings

### HIGH — Valid Git paths are corrupted before preview

`config/nvim/lua/novim/git.lua:74-126` parses line-oriented porcelain output by
stripping surrounding quotes and splitting every path containing ` -> `. That
does not decode Git's quoted path format and mistakes a literal ` -> ` inside a
filename for rename syntax.

An independent temporary fixture with three valid untracked paths reproduced
the failure:

- `arrow -> name.txt` became `name.txt"`;
- a filename containing `"` became `quote\\"name.txt`;
- a filename containing a tab became the literal text `tab\\tname.txt`.

All three previews returned `error: Could not access ...`. The workbench
therefore neither identifies nor renders all valid changed paths safely. Use a
NUL-delimited porcelain format and preserve path bytes exactly, including the
two-path rename record. Add regression coverage for literal arrows, quotes,
tabs, spaces, non-ASCII names, and renames before marking this resolved.

### HIGH — Closing a command-opened workbench breaks editor state

`config/nvim/lua/novim/workbench.lua:434-451` treats two workbench windows as a
reason to execute `:qall`, while `config/nvim/lua/novim/workbench.lua:471-488`
first replaces the active layout with those workbench buffers. When opened from
an edited buffer through `:Workbench` or Ctrl/Cmd+D, `q` exits the whole editor
if possible instead of returning to the prior buffer layout.

With an unsaved buffer, the independent diagnostic observed `E37: No write
since last change`; `state.is_open` had already changed to `false` while both
workbench windows remained open. Preserve and restore the prior layout for a
command-opened workbench, or otherwise provide a safe close path that uses the
existing unsaved-change confirmation contract and never leaves internal state
inconsistent. Add a regression test for saved and unsaved editor buffers.

### MEDIUM — Required interaction and invariance evidence is overstated

`tests/test_workbench.lua:202-225` changes pane width directly through the
Neovim API; it does not exercise an actual mouse-divider drag. The same test
does not capture a before-status snapshot and therefore cannot support the
handoff statement that `git status --short` is identical before and after. It
only checks that two path substrings are still present.

Record a real mouse drag in both directions with minimum-width behavior, and
compare an exact before/after status snapshot that includes staged, unstaged,
deleted, renamed, and untracked state. Keep this evidence local; it is not
hosted or production evidence.

### LOW — Candidate diff fails the required whitespace check

`git diff --check origin/main...HEAD` reports
`docs/tasks/current-task.md:195: new blank line at EOF.` Remove the extra blank
line and rerun the check.

## Acceptance evidence

| Criterion | Result | Evidence |
|---|---|---|
| Offline fixture launch | PASS | Independent `./tests/run_tests.sh` run; workbench initialized without plugin installation |
| Basic modified/untracked listing | PASS WITH GAP | Ordinary fixture paths pass; valid quoted/control-character paths fail as described above |
| Tracked diff rendering | PASS | Independent suite shows additions/deletions for the ordinary tracked fixture |
| Untracked file rendering | PASS WITH GAP | Ordinary untracked path passes; adversarial valid paths produce access errors |
| Mouse divider drag and minimums | NOT VERIFIED | Candidate test calls `nvim_win_set_width`; no actual mouse interaction evidence is recorded |
| Read-only Git behavior and status invariance | PASS WITH GAP | Product Git calls are read-only by inspection; candidate test does not perform the claimed exact snapshot comparison |
| Launcher isolation | PASS | Development and installed commands both report `0.1.7`; stdpaths remain under checkout `.dev-*` directories |
| No new dependency or unrelated site change | PASS | Real task diff adds no dependency and touches no upstream site asset |

## Validation performed

- `./tests/run_tests.sh`: passed, `4 total, 4 passed, 0 failed`.
- `bash -n bin/novim-dev tests/run_tests.sh`: passed.
- `./bin/novim-dev --version`: passed; reported `0.1.7-dev` and Neovim
  `0.12.5`.
- `/Users/mert/.local/bin/novim --version`: passed; reported installed
  `novim 0.1.7` and Neovim `0.12.5`.
- Headless stdpath inspection: config, data, state, and cache remained isolated
  under this checkout.
- Independent adversarial-path fixture: failed for literal arrow, quote, and
  tab filenames.
- Independent unsaved-buffer close diagnostic: failed with `E37` and
  inconsistent `is_open=false` state.
- `git diff --check origin/main...HEAD`: failed on the extra EOF blank line.
- Remote branch inspection: `origin/main` remains at `12327b7`; the remote task
  branch remains at `73f0f82`; candidate `6d6edd8` is local only.

## Required changes or blocker

Return the same `TASK-002` branch to `$stateless-implementer` and address all
four findings. Do not open a PR or merge this candidate. The next handoff must
include targeted regressions, exact Git-state invariance evidence, a real mouse
interaction record, and a clean `git diff --check` result.

## Next action

Run `$stateless-implementer` on `task/TASK-002-diff-workbench` to revise
`TASK-002`; stop again at `READY_FOR_REVIEW` with a new candidate commit.
