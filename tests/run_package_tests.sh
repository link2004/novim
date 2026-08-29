#!/bin/bash
# tests/run_package_tests.sh - Offline package/install and sync-boundary checks

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd -P)"
PACKAGER="$PROJECT_ROOT/bin/novim-dev-package"
RUN_ROOT="$(mktemp -d "${TMPDIR:-/tmp}/novim_package_test_XXXXXX")"
ARCHIVE_ONE="$RUN_ROOT/novim-custom-one.tar.gz"
ARCHIVE_TWO="$RUN_ROOT/novim-custom-two.tar.gz"
MANIFEST="$RUN_ROOT/manifest.txt"
INSTALLED_COMMAND="${HOME}/.local/bin/novim"
SOURCE_HEAD_BEFORE="$(git -C "$PROJECT_ROOT" rev-parse --verify HEAD)"
SOURCE_STATUS_BEFORE="$(git -C "$PROJECT_ROOT" status --porcelain=v1)"

cleanup() {
  if [[ -d "$RUN_ROOT" ]]; then
    rm -rf "$RUN_ROOT"
  fi
}
trap cleanup EXIT

fail() {
  echo "Error: $*" >&2
  exit 1
}

manifest_has() {
  if ! grep -Fqx "$1" "$MANIFEST"; then
    fail "package manifest is missing: $1"
  fi
}

installed_state() {
  if [[ -L "$INSTALLED_COMMAND" ]]; then
    printf 'symlink:%s\n' "$(readlink "$INSTALLED_COMMAND")"
  elif [[ -f "$INSTALLED_COMMAND" ]]; then
    shasum -a 256 "$INSTALLED_COMMAND"
  elif [[ -e "$INSTALLED_COMMAND" ]]; then
    stat -f '%Sp %z %N' "$INSTALLED_COMMAND"
  else
    printf '%s\n' 'absent'
  fi
}

if [[ ! -x "$PACKAGER" ]]; then
  fail "package helper is not executable: $PACKAGER"
fi
if ! command -v tar >/dev/null 2>&1; then
  fail "tar is required"
fi
if ! command -v git >/dev/null 2>&1; then
  fail "git is required"
fi
if ! command -v nvim >/dev/null 2>&1; then
  fail "nvim is required for installed package smoke validation"
fi

INSTALLED_STATE_BEFORE="$(installed_state)"
INSTALLED_VERSION_BEFORE=""
if [[ -x "$INSTALLED_COMMAND" ]]; then
  INSTALLED_VERSION_BEFORE="$("$INSTALLED_COMMAND" --version 2>&1)"
fi

VERSION="$(tr -d '[:space:]' < "$PROJECT_ROOT/VERSION")"
PACKAGE_ROOT="novim-custom-$VERSION"

echo "=== novim-custom Offline Package Tests ==="
echo "Project root: $PROJECT_ROOT"
echo "Package helper: $PACKAGER"

echo "--- Deterministic package and manifest ---"
"$PACKAGER" package "$ARCHIVE_ONE" >/dev/null
"$PACKAGER" package "$ARCHIVE_TWO" >/dev/null
if ! cmp -s "$ARCHIVE_ONE" "$ARCHIVE_TWO"; then
  fail "repeated package creation is not byte-identical"
fi
if "$PACKAGER" package "$ARCHIVE_ONE" >/dev/null 2>&1; then
  fail "package helper overwrote an existing archive"
fi

tar -tzf "$ARCHIVE_ONE" > "$MANIFEST"
manifest_has "$PACKAGE_ROOT/"
manifest_has "$PACKAGE_ROOT/bin/"
manifest_has "$PACKAGE_ROOT/bin/novim-dev"
manifest_has "$PACKAGE_ROOT/config/"
manifest_has "$PACKAGE_ROOT/config/nvim/"
manifest_has "$PACKAGE_ROOT/config/nvim/init.lua"
manifest_has "$PACKAGE_ROOT/config/nvim/lua/novim/workbench.lua"
manifest_has "$PACKAGE_ROOT/config/nvim/pack/plugins/start/gitsigns.nvim/lua/gitsigns.lua"
manifest_has "$PACKAGE_ROOT/VERSION"
manifest_has "$PACKAGE_ROOT/LICENSE"
manifest_has "$PACKAGE_ROOT/THIRD_PARTY_LICENSES.md"

if grep -Eq '(^|/)\.git(/|$)|(^|/)\.dev-[^/]*(/|$)' "$MANIFEST"; then
  fail "package manifest contains Git metadata or development runtime state"
fi
if grep -Eiq '(^|/)(\.env([.]|$)|.*credential.*|.*secret.*|.*\.(pem|key|sqlite|db))(/|$)' "$MANIFEST"; then
  fail "package manifest contains a private or credential-like entry"
fi
if grep -Fqx "$PACKAGE_ROOT/bin/novim" "$MANIFEST"; then
  fail "package manifest contains the installed-release launcher"
fi
echo "  PASS: allowlisted contents and deterministic archive"

echo "--- Temporary install and launcher isolation ---"
INSTALL_ROOT="$(cd "$RUN_ROOT" && pwd -P)/install"
"$PACKAGER" install "$ARCHIVE_ONE" "$INSTALL_ROOT" >/dev/null
[[ -x "$INSTALL_ROOT/bin/novim-dev" ]] || fail "installed launcher is not executable"
[[ ! -e "$INSTALL_ROOT/bin/novim" ]] || fail "install created an installed-release alias"
[[ ! -e "$INSTALL_ROOT/.git" ]] || fail "install extracted Git metadata"
NONEMPTY_ROOT="$RUN_ROOT/nonempty-install"
mkdir -p "$NONEMPTY_ROOT"
touch "$NONEMPTY_ROOT/preserved-marker"
if "$PACKAGER" install "$ARCHIVE_ONE" "$NONEMPTY_ROOT" >/dev/null 2>&1; then
  fail "installer overwrote a nonempty target"
fi
[[ -f "$NONEMPTY_ROOT/preserved-marker" ]] || fail "nonempty target was altered"
diff -ru "$PROJECT_ROOT/config/nvim" "$INSTALL_ROOT/config/nvim" >/dev/null || fail "installed config differs from package source"
cmp -s "$PROJECT_ROOT/VERSION" "$INSTALL_ROOT/VERSION" || fail "installed VERSION differs"
cmp -s "$PROJECT_ROOT/LICENSE" "$INSTALL_ROOT/LICENSE" || fail "installed LICENSE differs"
cmp -s "$PROJECT_ROOT/THIRD_PARTY_LICENSES.md" "$INSTALL_ROOT/THIRD_PARTY_LICENSES.md" || fail "installed attribution differs"

PACKAGE_VERSION_OUTPUT="$("$INSTALL_ROOT/bin/novim-dev" --version)"
[[ "$PACKAGE_VERSION_OUTPUT" == *"novim-dev $VERSION-dev (custom checkout)"* ]] || fail "installed version identity mismatch"
PACKAGE_HELP_OUTPUT="$("$INSTALL_ROOT/bin/novim-dev" --help)"
[[ "$PACKAGE_HELP_OUTPUT" == *"Configuration root:"* ]] || fail "installed launcher help mismatch"

NOVIM_PACKAGE_ROOT="$INSTALL_ROOT" "$INSTALL_ROOT/bin/novim-dev" --headless \
  -c "lua assert(vim.fs.normalize(vim.fn.stdpath('config')) == vim.fs.normalize(os.getenv('NOVIM_PACKAGE_ROOT') .. '/config/nvim'), 'package config path mismatch') assert(vim.fn.exists(':Workbench') == 2, 'Workbench command missing') assert(vim.fn.exists(':DiffWorkbench') == 2, 'DiffWorkbench command missing') assert(vim.fn.exists(':Settings') == 2, 'Settings command missing')" \
  -c 'qall!'

[[ -d "$INSTALL_ROOT/.dev-data" ]] || fail "package data path was not isolated"
[[ -d "$INSTALL_ROOT/.dev-state" ]] || fail "package state path was not isolated"
[[ -d "$INSTALL_ROOT/.dev-cache" ]] || fail "package cache path was not isolated"
echo "  PASS: temporary install, version/help, headless startup, and isolated runtime"

echo "--- Offline fixture validation of explicit sync boundaries ---"
SYNC_RUNBOOK="$PROJECT_ROOT/docs/UPSTREAM_SYNC.md"
for phrase in \
  'git fetch --no-tags upstream main' \
  'BASELINE="$(git rev-parse --verify HEAD)"' \
  'git diff --stat "$BASELINE..$UPSTREAM_MAIN"' \
  'git switch -c task/TASK-NNN-upstream-sync-review "$BASELINE"' \
  'git merge --no-ff --no-commit "$UPSTREAM_MAIN"' \
  'git cherry-pick --abort' \
  'git merge --abort' \
  'git revert -m 1 <sync-merge-commit>'; do
  grep -Fq "$phrase" "$SYNC_RUNBOOK" || fail "sync runbook is missing: $phrase"
done

REMOTE_REPO="$RUN_ROOT/upstream-fixture.git"
SEED_REPO="$RUN_ROOT/upstream-seed"
SYNC_REPO="$RUN_ROOT/sync-review"
git init --bare -q "$REMOTE_REPO"
git init -q "$SEED_REPO"
git -C "$SEED_REPO" config user.email 'package-test@example.com'
git -C "$SEED_REPO" config user.name 'Package Test Runner'
git -C "$SEED_REPO" commit --allow-empty -q -m 'fixture baseline'
git -C "$SEED_REPO" branch -M main
git -C "$SEED_REPO" remote add origin "$REMOTE_REPO"
git -C "$SEED_REPO" push -q origin main
git clone -q --branch main "$REMOTE_REPO" "$SYNC_REPO"
git -C "$SYNC_REPO" remote rename origin upstream
FIXTURE_BASELINE="$(git -C "$SYNC_REPO" rev-parse --verify HEAD)"
git -C "$SEED_REPO" commit --allow-empty -q -m 'fixture candidate'
git -C "$SEED_REPO" push -q origin main
git -C "$SYNC_REPO" fetch --no-tags upstream main >/dev/null
FIXTURE_UPSTREAM="$(git -C "$SYNC_REPO" rev-parse --verify upstream/main)"
[[ "$FIXTURE_BASELINE" != "$FIXTURE_UPSTREAM" ]] || fail "fixture upstream did not advance"
git -C "$SYNC_REPO" diff --stat "$FIXTURE_BASELINE..$FIXTURE_UPSTREAM" >/dev/null
[[ "$(git -C "$SYNC_REPO" rev-parse --verify HEAD)" == "$FIXTURE_BASELINE" ]] || fail "fixture compare mutated the review HEAD"
[[ -z "$(git -C "$SYNC_REPO" status --porcelain=v1)" ]] || fail "fixture compare dirtied the review tree"
echo "  PASS: runbook checkpoints and local-only fetch/compare fixture"

echo "--- Existing release and checkout invariance ---"
[[ "$(git -C "$PROJECT_ROOT" rev-parse --verify HEAD)" == "$SOURCE_HEAD_BEFORE" ]] || fail "source checkout HEAD changed"
[[ "$(git -C "$PROJECT_ROOT" status --porcelain=v1)" == "$SOURCE_STATUS_BEFORE" ]] || fail "source checkout status changed"
[[ "$(installed_state)" == "$INSTALLED_STATE_BEFORE" ]] || fail "installed novim command changed"
if [[ -x "$INSTALLED_COMMAND" ]]; then
  [[ "$("$INSTALLED_COMMAND" --version 2>&1)" == "$INSTALLED_VERSION_BEFORE" ]] || fail "installed novim version output changed"
fi
echo "  PASS: installed novim and source checkout remain unchanged"

echo "=== Offline Package Tests Passed ==="
