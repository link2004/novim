# Current Task

Task ID: `TASK-006`
Status: `ACCEPTED`
Delivery policy: `LIGHTWEIGHT`
Base branch: `main`
Task branch: `task/TASK-006-package-upstream-sync`
Expected baseline: `bcdd81ce9e9d0a3badc21d220f98d31600167059` (`origin/main`)
Pull request: `https://github.com/medonmez/novim-custom/pull/8` (`MERGED`)
Merge commit: `86ee75844308afbaf7e055bd86b6e5ca8b38a903` (`origin/main`)

## Outcome

Make the local `novim-custom` derivative reproducibly packageable for local
use and document a safe, reviewable upstream synchronization procedure while
preserving the separate `novim-dev` launcher and the installed `novim`
release boundary.

## Context

TASK-001 established the isolated `novim-dev` command; TASK-002 through
TASK-004 delivered the read-only two-pane workbench, project browser/settings,
and source navigation; TASK-005 added the deterministic local smoke layer.
The next slice is operational: make the derivative’s local distribution shape
explicit and leave a durable runbook for comparing and selectively syncing
upstream changes.

## In scope

- Define and implement the local packaging/install path for this derivative,
  including the required launcher, configuration, bundled runtime assets, and
  attribution/license files.
- Keep the local package or installation target distinct from the installed
  upstream `novim` command and its data directory.
- Document version/identity, package contents, local install verification, and
  rollback or removal boundaries for the derivative.
- Document a safe upstream sync procedure using the existing `upstream` remote:
  fetch explicitly, compare against a named baseline, inspect changes on an
  isolated branch, and merge or select changes only after review.
- Add deterministic local validation for package contents, install isolation,
  launcher behavior, and the documented sync workflow’s non-destructive
  boundaries.

## Out of scope

- Publishing a hosted release, creating a public package-manager formula, or
  changing the upstream project.
- Running an upstream fetch, merge, rebase, cherry-pick, or other history
  mutation as part of normal `novim-dev` startup or package installation.
- Overwriting, upgrading, or removing the installed `/Users/mert/.local/bin/novim`
  or `/Users/mert/.local/share/novim` release without an explicit separate
  user action.
- New product features, Git mutation controls, network behavior by default,
  credentials, private data, or a plugin-manager dependency.
- Claiming hosted, production, recovery, or customer-acceptance evidence from
  local packaging checks.

## Acceptance criteria

- [x] A documented local packaging/install command produces or installs the
      derivative from this checkout using a temporary target during tests.
- [x] The package contains the required `novim-dev` launcher, `config/nvim`
      tree, bundled runtime assets, version identity, and license/attribution
      files, with no `.git` metadata, `.dev-*` state, credentials, or private
      runtime data included.
- [x] A temporary-target install runs `novim-dev --version` and a headless
      smoke check successfully without changing the installed `novim` command
      or the source checkout.
- [x] The safe upstream sync runbook documents explicit fetch/compare steps,
      isolated branches, review checkpoints, conflict handling, and a
      reversible recovery path without implying automatic synchronization.
- [x] The documented workflow preserves the read-only Git, isolated-runtime,
      no-default-network, and installed-release boundaries accepted by
      TASK-001 through TASK-005.
- [x] Existing `./tests/run_tests.sh`, launcher syntax, version checks, and
      `git diff --check` remain passing, with package/install checks offline.

## Decision guardrails

- Keep package creation and local install deterministic and offline; upstream
  network access is only an explicit sync action described in the runbook.
- Use temporary prefixes and fixtures for validation. Do not write to the
  user’s actual installed `novim` paths or normal Neovim configuration.
- Preserve upstream attribution and all applicable MIT/third-party license
  notices; do not package ignored runtime state or secrets.
- Keep all implementation on this isolated task branch and stop at a local
  handoff for orchestrator review. No direct default-branch writes.
- Treat package artifacts, local install behavior, and sync instructions as
  local evidence only; do not describe them as a hosted release or production
  deployment.

## Relevant areas

- `bin/novim-dev` and `bin/novim` — launcher identity and installed-release
  boundary.
- `config/nvim/` and `config/nvim/pack/` — runtime configuration and bundled
  assets that a local package must preserve.
- `VERSION`, `LICENSE`, and `THIRD_PARTY_LICENSES.md` — version and attribution
  inputs.
- `install.sh`, `README.md`, and `docs/architecture.md` — existing upstream
  installation documentation and local derivative architecture.
- `docs/repository.md`, `docs/adr/`, and the Git remotes — synchronization
  contract and upstream boundary.
- `tests/` — offline package/install and regression validation.

## Required validation

- Inspect the real package manifest/archive and verify its file list and
  absence of `.git`, `.dev-*`, secrets, and private runtime artifacts.
- Install or link into an explicitly temporary prefix, run version/help and a
  headless smoke check, then verify the original checkout and installed
  `novim` remain unchanged.
- Run the documented sync procedure in a non-destructive dry-run or fixture
  repository where possible; do not fetch or mutate upstream history as an
  unapproved side effect.
- Run `./tests/run_tests.sh`, `bash -n` on changed shell scripts, both
  development and installed version checks, and `git diff --check`.
- Keep local package/install and repository-branch evidence separate from
  hosted, production, recovery, and customer-acceptance claims.

## Blockers and dependencies

- No product decision is open for this bounded operational slice.
- Dependency: TASK-005 is accepted on `origin/main` at merge commit
  `cd938e2ce0ef9e792b2979cd325e614a65d42590`.
- Upstream synchronization is documented but must remain an explicit,
  user-mediated action; no credentials or external service is required for
  planning or local package validation.

## Implementation handoff

Status: `ACCEPTED`

Delivery record: reviewed `APPROVED` at candidate
`08ca56ca7efcecb759412d4b6cafa60f33921d6a`, merged through PR #8 as commit
`86ee75844308afbaf7e055bd86b6e5ca8b38a903` on `origin/main`. All acceptance
criteria passed observed local validation; evidence is local only.

Backlog status: TASK-001 through TASK-006 are all accepted. No next task is
planned; a fresh user brief is required before planning the next slice.
Candidate commit: `08ca56ca7efcecb759412d4b6cafa60f33921d6a`

Outcome summary: Added an offline, deterministic allowlist package/archive
helper and empty-target installer for the separate `novim-dev` derivative;
documented package/removal boundaries and an explicit, review-gated upstream
sync procedure; and added offline package/install/fixture validation to the
existing test runner.

Files changed:

- `bin/novim-dev-package` — deterministic `package` and safe `install`
  commands with manifest, path, type, and private/runtime-entry validation.
- `tests/run_package_tests.sh` — archive determinism/manifest checks,
  temporary install and headless launcher smoke, non-overwrite checks, local
  fixture fetch/compare, and source/installed-release invariance checks.
- `tests/run_tests.sh` and `tests/run_smoke_tests.sh` — package suite entry
  point and tracked-product regression check compatible with new task files.
- `docs/LOCAL_DISTRIBUTION.md` — identity, contents, local install,
  verification, removal, and isolation guide.
- `docs/UPSTREAM_SYNC.md` — explicit fetch/compare, isolated-branch review,
  conflict handling, and recovery runbook.
- `README.md`, `docs/architecture.md`, and `docs/repository.md` — local
  distribution and synchronization documentation routes.
- `docs/tasks/current-task.md`, `docs/tasks/backlog.md`, `project-state.md`,
  and `docs/project.json` — TASK-006 state, actual `origin/main` baseline,
  and handoff records.

Validation performed:

- `./tests/run_tests.sh`: PASS (21/21 workbench tests, offline package tests,
  and 6/6 regression smoke tests).
- `./tests/run_package_tests.sh`: PASS (byte-identical repeated archives,
  required manifest and exclusions, temporary install/version/help/headless
  smoke, nonempty-target/overwrite denials, local-only sync fixture, source
  and installed-release invariance).
- `./tests/run_tests.sh --smoke`: PASS (6/6 regression smoke tests).
- Concurrent `./tests/run_smoke_tests.sh` and `./tests/run_tests.sh`: PASS
  (both processes exit 0; package and isolated-runtime checks remain clean).
- `bash -n bin/novim-dev bin/novim-dev-package tests/run_tests.sh
  tests/run_smoke_tests.sh tests/run_package_tests.sh`: PASS.
- `python3 -m json.tool docs/project.json`: PASS.
- `./bin/novim-dev --version`: PASS (`0.1.7-dev`, Neovim `v0.12.5`).
- `/Users/mert/.local/bin/novim --version`: PASS (`0.1.7`, unchanged).
- `git diff --check`: PASS.

Acceptance evidence: all six TASK-006 acceptance criteria pass through the
package manifest/install assertions, local runbooks and fixture workflow,
existing read-only/runtime/version checks, and offline full test runner.

Residual risks / known gaps: local package and fixture evidence only; no
upstream fetch, hosted release, production deployment, recovery exercise, or
customer-acceptance claim was made. The optional `novim-dev` convenience link
remains an explicit user action.
