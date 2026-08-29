# Latest Review

Updated: 2026-08-29
Task ID: `TASK-005`
Local verdict: `CHANGES_REQUESTED`
Delivery policy: `LIGHTWEIGHT`
Baseline: `f01b7232f4dd06f5d4ccf4ad2d7fa80c5509d2ab` (`origin/main`)
Candidate: `fc4086be3ca6bad8b75189fdaa00dd02ba09bcf0`
Task branch: `task/TASK-005-regression-smoke-tests`
Pull request: `NOT_OPEN`
Remote checks: `OPTIONAL / NOT_RUN`
Merge status: `NOT_DELIVERED`
Target branch contains change: `NO`

## Review result

The real candidate diff was inspected against the actual `origin/main` merge
baseline. The additive smoke suite covers the accepted workbench, source
navigation, settings, and read-only Git behavior, and the required sequential
local commands pass. The task remains active because the runner does not yet
prove the launcher boundary and its post-run cleanup check is ineffective on
this macOS host.

## Findings

### High — Headless smoke execution bypasses the launcher’s config-loading path

`tests/run_smoke_tests.sh:109` invokes `novim-dev` with
`-u "$PROJECT_ROOT/config/nvim/init.lua"`. This explicitly supplies the
checkout init file, so the smoke suite can pass even if the launcher’s normal
config selection or checkout-root resolution is wrong. The external-working-
directory and symlink checks at `tests/run_smoke_tests.sh:73-94` only run
`--version`; they do not exercise a real Neovim startup from those invocation
forms. The Lua assertion at `tests/test_smoke.lua:183` is also permissive: any
path containing the substring `config` satisfies it.

Required change: run the headless suite through the launcher’s normal startup
path, loading the test after the launcher has initialized its default config;
do not pass the repository init file as a substitute for launcher coverage.
Assert the exact checkout config path and exercise the same real headless
startup from an external cwd and a symlinked launcher (or equivalent
run-owned invocation that proves the resolved root).

### Medium — Fixture-residue verification scans the wrong temporary root on macOS

`tests/run_smoke_tests.sh:115-123` scans only `/tmp/*_smoke_*`, but this host’s
`vim.fn.tempname()` returns paths under `/var/folders/.../T/nvim...`. Therefore
the advertised post-run residue check is a no-op for the fixtures created by
`tests/test_smoke.lua`, and it cannot detect a leaked fixture on this platform.
The Lua cleanup calls also ignore the return value of `vim.fn.delete`, so the
shell check is the only external confirmation for cleanup failures.

Required change: use a run-specific temporary root known to both the shell
runner and Lua suite (or scan the actual platform temp root with an exact
run-owned marker), assert cleanup there, and avoid treating a hard-coded
`/tmp` glob as cross-platform evidence. Preserve nonzero exit behavior when
cleanup verification fails.

### Medium — Concurrent test processes race on shared development state

Running the candidate’s smoke runner concurrently with the full runner caused
`tests/test_smoke.lua:575` to fail during the settings persistence roundtrip
(`expected true, got false`). Both Neovim processes use the shared checkout
`.dev-state` settings file. The documented commands are sequential, so this is
not a standalone acceptance failure, but it is a reproducibility risk for
parallel local or CI invocations and should be addressed if parallel use is
intended.

## Acceptance evidence

| Criterion | Result | Evidence |
|---|---|---|
| Documented local smoke command and nonzero failure path | PARTIAL | `tests/run_smoke_tests.sh` and `tests/run_tests.sh --smoke` exist and sequential failure propagation is wired through `set -e`/Neovim exit status; cleanup failure detection is incomplete on this host. |
| Checkout config, isolated paths, and installed-release boundary | PARTIAL | Isolated `.dev-*` paths and installed `/Users/mert/.local/bin/novim` version checks pass, but the headless path explicitly supplies the checkout init and does not fully prove launcher config resolution. |
| Workbench layout, navigation, settings, and unsaved buffers | PASS | Sequential smoke suite passed the six smoke tests, including two panes, source editing handoff, directory preview, settings paths, and buffer preservation. |
| Git rendering and byte-for-byte invariance | PASS | Sequential smoke suite passed modified, deleted, renamed, untracked, binary, clean, and non-Git fixture checks plus exact before/after status and `git diff HEAD` comparisons. |
| Dotfile, persistence, malformed-settings, and write-failure contracts | PASS | Sequential smoke and existing integration suites passed these cases. |
| Offline, deterministic, cleanup, and dependency boundary | PARTIAL | No network or new dependency was introduced and sequential runs pass, but cleanup scanning is not effective under this host temp layout; concurrent state races were also observed. |
| Existing runner, syntax, versions, and diff check | PASS | `./tests/run_tests.sh`, `./tests/run_tests.sh --smoke`, `bash -n bin/novim-dev tests/run_tests.sh tests/run_smoke_tests.sh`, both version checks, and `git diff --check` passed when run sequentially. |

## Validation performed

- Inspected `AGENTS.md`, `docs/repository.md`, `project-state.md`, the current
  task, backlog, latest review, architecture/product/ADR records, remotes,
  branch ancestry, candidate commit, and complete candidate diff.
- Confirmed the checked-out branch is
  `task/TASK-005-regression-smoke-tests`, clean before this review, with
  candidate `fc4086be3ca6bad8b75189fdaa00dd02ba09bcf0` one commit above
  `origin/main` at `f01b7232f4dd06f5d4ccf4ad2d7fa80c5509d2ab`.
- `./tests/run_smoke_tests.sh`: passed sequentially twice, 6/6 each time.
- `./tests/run_tests.sh`: passed sequentially, 21/21 integration tests and 6/6
  smoke tests.
- `./tests/run_tests.sh --smoke`: passed, 6/6.
- `bash -n bin/novim-dev tests/run_tests.sh tests/run_smoke_tests.sh`: passed.
- `./bin/novim-dev --version`: passed, `0.1.7-dev` / Neovim `v0.12.5`.
- `/Users/mert/.local/bin/novim --version`: passed, installed `0.1.7`.
- `git diff --check origin/main...HEAD`: passed.
- Direct `./bin/novim-dev --headless -c "luafile .../tests/test_smoke.lua"`
  passed 6/6, demonstrating the normal launcher path separately from the
  candidate runner; this is not credited as candidate coverage because the
  runner itself still uses `-u`.
- `vim.fn.tempname()` resolved under `/var/folders/.../T` on this macOS host,
  confirming that the runner’s `/tmp` residue glob does not cover its own
  fixture paths.
- Concurrent smoke/full-runner execution reproduced the shared `.dev-state`
  settings race at `tests/test_smoke.lua:575`.
- Working-tree status remained clean apart from ignored `.dev-state/` runtime
  artifacts; no PR was opened and no remote delivery was attempted.

Evidence is local review evidence only; no hosted, production, recovery, or
customer-acceptance claim is made.

## Delivery decision

`CHANGES_REQUESTED`. Do not open or merge a PR for
`fc4086be3ca6bad8b75189fdaa00dd02ba09bcf0`. Return the same isolated branch to
`$stateless-implementer` for the required smoke-runner revisions.

## Next action

Run `$stateless-implementer` on
`task/TASK-005-regression-smoke-tests`; fix the two required findings, rerun
the full local validation, and stop at `READY_FOR_REVIEW` with a new handoff.
