# Local novim-custom Distribution

This is a local distribution path for this checkout. It is not a hosted
release, a package-manager formula, or an update path for the installed
upstream `novim` command.

## Identity and package contents

The checkout's `VERSION` file is the upstream-compatible base version. A
package is named `novim-custom-<VERSION>.tar.gz`; the bundled launcher reports
the same identity as `<VERSION>-dev (custom checkout)` through the separate
`novim-dev` command.

The archive is an explicit allowlist, containing:

- `bin/novim-dev`;
- the complete `config/nvim/` tree, including the bundled runtime plugin;
- `VERSION`;
- `LICENSE`; and
- `THIRD_PARTY_LICENSES.md`.

It intentionally does not contain `bin/novim`, Git metadata, `.dev-*` runtime
directories, credentials, environment files, or private runtime data. The
installed upstream `novim` release remains outside this package.

## Create and test a local package

Packaging is deterministic and offline. Give it a new output path; the helper
refuses to overwrite an existing archive.

```bash
PACKAGE_TMP="$(mktemp -d "${TMPDIR:-/tmp}/novim-custom-package.XXXXXX")"
ARCHIVE="$PACKAGE_TMP/novim-custom.tar.gz"

./bin/novim-dev-package package "$ARCHIVE"
tar -tzf "$ARCHIVE"

INSTALL_ROOT="$PACKAGE_TMP/install"
./bin/novim-dev-package install "$ARCHIVE" "$INSTALL_ROOT"
"$INSTALL_ROOT/bin/novim-dev" --version
NOVIM_PACKAGE_ROOT="$INSTALL_ROOT" "$INSTALL_ROOT/bin/novim-dev" --headless \
  -c "lua assert(vim.fs.normalize(vim.fn.stdpath('config')) == vim.fs.normalize(os.getenv('NOVIM_PACKAGE_ROOT') .. '/config/nvim'))" \
  -c 'qall!'
```

The install command accepts only a new or empty, explicitly named directory.
It extracts the package there and never creates an alias named `novim`. For a
user-local installation, use a dedicated derivative directory and inspect any
existing link before creating the optional convenience link:

```bash
DERIVATIVE_ROOT="$HOME/.local/share/novim-custom"
./bin/novim-dev-package install /path/to/novim-custom.tar.gz "$DERIVATIVE_ROOT"
mkdir -p "$HOME/.local/bin"
# First confirm that this path is absent or already points to the derivative.
ln -s "$DERIVATIVE_ROOT/bin/novim-dev" "$HOME/.local/bin/novim-dev"
```

This link is separate from `$HOME/.local/bin/novim`, and the install root is
separate from `$HOME/.local/share/novim`. Do not replace an existing nonempty
derivative root with an in-place extraction: verify the new package in a
temporary root first, then perform an explicit user-mediated replacement.

## Verification and removal boundaries

Verify the package manifest, `novim-dev --version`, and a headless launch from
the temporary or dedicated derivative root before using it. A launch may
create `.dev-data/`, `.dev-state/`, and `.dev-cache/` below that derivative
root; those are runtime state and are never package inputs.

Removal is limited to the exact derivative root and, after checking its link
target, the optional `$HOME/.local/bin/novim-dev` link. Never remove or
overwrite `$HOME/.local/bin/novim`, `$HOME/.local/share/novim`, the normal
Neovim configuration, or the checkout as part of this workflow. Temporary
package and install roots are local validation artifacts and may be removed
after the checks finish.

No package or install command fetches upstream data, runs `novim --update`, or
performs a Git mutation. Upstream synchronization is a separate, explicit
workflow described in [UPSTREAM_SYNC.md](UPSTREAM_SYNC.md).

All results from these commands are local development evidence only; they do
not establish a hosted, production, recovery, or customer-acceptance release.
