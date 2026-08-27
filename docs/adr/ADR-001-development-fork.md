# ADR-001: Isolated Local Development Fork and Command

- Status: `ACCEPTED FOR BOOTSTRAP`
- Date: 2026-08-27
- Scope: local development setup

## Decision

Maintain the derivative in `/Users/mert/novim-custom`, based on the upstream
`link2004/novim` repository, and develop it through a separate command named
`novim-dev`.

The installed upstream `novim` command remains the stable fallback. The
development command must load the checkout's configuration and use distinct
writable data/state paths. A GitHub fork is deferred; the current clone's
`origin` is the upstream repository and must not be used for pushing changes.

## Rationale

- The installed release has no Git history and its updater can overwrite local
  edits.
- novim's behavior is primarily a Neovim configuration plus a small wrapper, so
  a local fork gives direct, reviewable control with little packaging overhead.
- A separate command makes experiments reversible and prevents accidental
  changes to the user's existing editor setup.

## Consequences

- Upstream changes can be compared and selectively incorporated later.
- Local command installation must be maintained separately from upstream's
  `novim --update` path.
- The product name and remote delivery model remain open decisions for a later
  release; this ADR only fixes the local development boundary.
