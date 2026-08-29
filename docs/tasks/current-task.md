# Current Task

Updated: 2026-08-29
Task ID: `TASK-006`
Status: `PLANNED`
Delivery policy: `LIGHTWEIGHT`
Base branch: `main`
Task branch: `task/TASK-006-package-upstream-sync`
Expected baseline: `cd938e2ce0ef9e792b2979cd325e614a65d42590` (`origin/main`)
Pull request: `NOT_OPEN`
Remote checks: `OPTIONAL / NOT_RUN`

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

- [ ] A documented local packaging/install command produces or installs the
      derivative from this checkout using a temporary target during tests.
- [ ] The package contains the required `novim-dev` launcher, `config/nvim`
      tree, bundled runtime assets, version identity, and license/attribution
      files, with no `.git` metadata, `.dev-*` state, credentials, or private
      runtime data included.
- [ ] A temporary-target install runs `novim-dev --version` and a headless
      smoke check successfully without changing the installed `novim` command
      or the source checkout.
- [ ] The safe upstream sync runbook documents explicit fetch/compare steps,
      isolated branches, review checkpoints, conflict handling, and a
      reversible recovery path without implying automatic synchronization.
- [ ] The documented workflow preserves the read-only Git, isolated-runtime,
      no-default-network, and installed-release boundaries accepted by
      TASK-001 through TASK-005.
- [ ] Existing `./tests/run_tests.sh`, launcher syntax, version checks, and
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

Not started. Use `$stateless-implementer` on the recorded isolated branch and
stop at `READY_FOR_REVIEW` with a local validation summary.
