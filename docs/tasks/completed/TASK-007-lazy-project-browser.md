# TASK-007 — Lazy root-only project browser

- Status: `ACCEPTED`
- Delivery policy: `LIGHTWEIGHT`
- Merge commit: `d8f567a2b1b20d6ab9f9afba7e5ab9d2442ce1c9`
- Pull request: `#10` (`MERGED`)
- Candidate: `48931884e679c55c2e5eb536706efc0fcd14d249`

## Outcome

Replaced recursive startup project scanning with a root-only lazy browser.
Folders expand one level at a time through session-only double-click state;
refresh preserves valid expansions, new launches reset them, dotfile filtering
applies at every scanned level, and true symlink ancestor cycles are refused.

## Acceptance evidence

- Root-only, expansion/collapse, nested expansion, refresh/reset, dotfile,
  large/deep lazy-boundary, and symlink-cycle tests passed.
- Source preview/editing, unsaved-buffer preservation, read-only Git,
  isolated-runtime, installed-release, and no-default-network contracts
  remained green.
- `./tests/run_tests.sh`: 27/27 integration tests, offline package suite, and
  6/6 smoke tests passed; syntax, version, JSON, and `git diff --check`
  validation passed.

Evidence was local only; no hosted, production, recovery, or
customer-acceptance claim was made.
