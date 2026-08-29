# TASK-006 — Local packaging and upstream sync runbook

- Status: `ACCEPTED`
- Delivery policy: `LIGHTWEIGHT`
- Merge commit: `86ee75844308afbaf7e055bd86b6e5ca8b38a903`
- Pull request: `#8` (`MERGED`)

## Outcome

Added an offline deterministic package/install helper for the separate
`novim-dev` derivative, documented safe local distribution and explicit
upstream synchronization, and integrated package validation into the local
test runner.

## Acceptance evidence

- `./tests/run_tests.sh`: 21/21 workbench tests, package suite, and 6/6 smoke
  tests passed.
- Launcher syntax, version checks, JSON validation, and `git diff --check`
  passed.
- Package contents, exclusions, temporary installation, isolated runtime,
  non-overwrite behavior, and local sync-fixture boundaries passed.

Evidence was local only; no hosted, production, recovery, or
customer-acceptance claim was made.
