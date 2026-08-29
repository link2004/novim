#!/bin/bash
# tests/run_smoke_tests.sh - Run deterministic regression smoke tests for novim-dev
# Part of novim custom derivative
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd -P)"
LAUNCHER="$PROJECT_ROOT/bin/novim-dev"

echo "=== novim-dev Regression Smoke Test Runner ==="
echo "Project root: $PROJECT_ROOT"
echo "Launcher:     $LAUNCHER"

# Check required binaries
if ! command -v nvim >/dev/null 2>&1; then
  echo "Error: nvim is required but not found in PATH." >&2
  exit 1
fi

if ! command -v git >/dev/null 2>&1; then
  echo "Error: git is required but not found in PATH." >&2
  exit 1
fi

if [[ ! -x "$LAUNCHER" ]]; then
  echo "Error: Launcher $LAUNCHER is not executable." >&2
  exit 1
fi

# Create a run-specific temporary fixture root (works cross-platform on macOS and Linux)
RUN_TEMP_ROOT="$(mktemp -d "${TMPDIR:-/tmp}/novim_smoke_run_XXXXXX")"
export NOVIM_SMOKE_TEMP_ROOT="$RUN_TEMP_ROOT"
export NOVIM_PROJECT_ROOT="$PROJECT_ROOT"

CLEANUP_DIRS=("$RUN_TEMP_ROOT")
cleanup() {
  for d in "${CLEANUP_DIRS[@]}"; do
    if [[ -d "$d" ]]; then
      rm -rf "$d"
    fi
  done
}
trap cleanup EXIT

# Snapshot the checksum of every tracked product source file under bin/ and
# config/ before test execution. Step 4 compares against this snapshot so
# only mutations caused by the tests themselves fail the run; uncommitted
# task-branch changes made before the run are legitimate.
PRODUCT_SNAPSHOT="$(cd "$PROJECT_ROOT" && git ls-files -- bin/ config/ | while IFS= read -r path; do
  if [[ -f "$path" ]]; then
    shasum -a 256 "$path"
  fi
done)"

echo ""
echo "--- Step 1: CLI and Flag Smoke Checks ---"

# 1.1 Test --version
VERSION_OUT="$("$LAUNCHER" --version)"
echo "  [CLI] Checking --version output:"
echo "        $VERSION_OUT"
if [[ "$VERSION_OUT" != *"novim-dev"* || "$VERSION_OUT" != *"-dev (custom checkout)"* || "$VERSION_OUT" != *"powered by NVIM"* ]]; then
  echo "Error: --version output format mismatch." >&2
  exit 1
fi
echo "  ✓ PASS: --version reports custom checkout and Neovim engine"

# 1.2 Test -v alias
V_OUT="$("$LAUNCHER" -v)"
if [[ "$V_OUT" != "$VERSION_OUT" ]]; then
  echo "Error: -v output does not match --version output." >&2
  exit 1
fi
echo "  ✓ PASS: -v alias matches --version"

# 1.3 Test --help
HELP_OUT="$("$LAUNCHER" --help)"
if [[ "$HELP_OUT" != *"Usage: novim-dev"* || "$HELP_OUT" != *"Configuration root:"* || "$HELP_OUT" != *"Runtime state:"* ]]; then
  echo "Error: --help output format mismatch." >&2
  exit 1
fi
echo "  ✓ PASS: --help reports isolated configuration and runtime directories"

echo ""
echo "--- Step 2: Working Directory and Symlink Isolation ---"

# 2.1 Invocation from external working directory (CLI + real headless startup)
EXTERNAL_TMP="$(mktemp -d "${TMPDIR:-/tmp}/novim_ext_cwd_XXXXXX")"
CLEANUP_DIRS+=("$EXTERNAL_TMP")

EXT_VERSION="$(cd "$EXTERNAL_TMP" && "$LAUNCHER" --version)"
if [[ "$EXT_VERSION" != *"novim-dev"* ]]; then
  echo "Error: Invocation from external directory failed." >&2
  exit 1
fi

(cd "$EXTERNAL_TMP" && "$LAUNCHER" --headless -c "lua assert(vim.fs.normalize(vim.fn.stdpath('config')) == vim.fs.normalize('$PROJECT_ROOT/config/nvim'), 'external cwd config path mismatch') assert(vim.fs.normalize(vim.fn.stdpath('data')) == vim.fs.normalize('$PROJECT_ROOT/.dev-data/nvim'), 'external cwd data path mismatch')" -c "qall!")
echo "  ✓ PASS: External working directory resolves repository root in CLI and headless startup"

# 2.2 Invocation via symlinked launcher (CLI + real headless startup)
SYMLINK_DIR="$(mktemp -d "${TMPDIR:-/tmp}/novim_symlink_XXXXXX")"
CLEANUP_DIRS+=("$SYMLINK_DIR")
ln -s "$LAUNCHER" "$SYMLINK_DIR/novim-dev-symlink"

LINK_VERSION="$("$SYMLINK_DIR/novim-dev-symlink" --version)"
if [[ "$LINK_VERSION" != *"novim-dev"* ]]; then
  echo "Error: Invocation via symlink failed." >&2
  exit 1
fi

(cd "$EXTERNAL_TMP" && "$SYMLINK_DIR/novim-dev-symlink" --headless -c "lua assert(vim.fs.normalize(vim.fn.stdpath('config')) == vim.fs.normalize('$PROJECT_ROOT/config/nvim'), 'symlink config path mismatch')" -c "qall!")
echo "  ✓ PASS: Symlinked launcher resolves real repository root in CLI and headless startup"

# 2.3 Installed novim independence check
if [[ -x "/Users/mert/.local/bin/novim" ]]; then
  INSTALLED_VERSION="$(/Users/mert/.local/bin/novim --version 2>&1 || true)"
  echo "  [INFO] Installed novim version: $INSTALLED_VERSION"
  if [[ "$INSTALLED_VERSION" == *"-dev (custom checkout)"* ]]; then
    echo "Error: Installed novim was overwritten by development launcher." >&2
    exit 1
  fi
  echo "  ✓ PASS: Installed novim binary remains untouched and independent"
fi

echo ""
echo "--- Step 3: Headless Neovim Regression Smoke Suite ---"
# Note: uses normal launcher startup path (loads checkout config automatically, without -u)
"$LAUNCHER" --headless -c "luafile $PROJECT_ROOT/tests/test_smoke.lua"
echo "  ✓ PASS: All headless regression smoke tests passed under normal launcher startup"

echo ""
echo "--- Step 4: Post-Run Artifact and Cleanup Verification ---"

# Verify no leftover test fixtures in the run-specific temp root
LEFTOVER_COUNT=0
if [[ -d "$RUN_TEMP_ROOT" ]]; then
  shopt -s nullglob dotglob
  LEFTOVER_ENTRIES=("$RUN_TEMP_ROOT"/*)
  shopt -u nullglob dotglob
  LEFTOVER_COUNT=${#LEFTOVER_ENTRIES[@]}
  if [[ "$LEFTOVER_COUNT" -gt 0 ]]; then
    echo "Error: Detected uncleaned smoke fixture(s) in $RUN_TEMP_ROOT:" >&2
    for entry in "${LEFTOVER_ENTRIES[@]}"; do
      echo "  - $entry" >&2
    done
    exit 1
  fi
fi
echo "  ✓ PASS: Zero fixture residue left in run temporary root ($RUN_TEMP_ROOT)"

# Verify tracked product source files were not modified by test execution:
# compare current checksums against the snapshot taken before the run. A task
# branch may legitimately contain uncommitted product changes made before the
# run; only changes made DURING the run fail this check.
PRODUCT_SNAPSHOT_END="$(cd "$PROJECT_ROOT" && git ls-files -- bin/ config/ | while IFS= read -r path; do
  if [[ -f "$path" ]]; then
    shasum -a 256 "$path"
  fi
done)"
if [[ "$PRODUCT_SNAPSHOT_END" != "$PRODUCT_SNAPSHOT" ]]; then
  echo "Error: Product code in bin/ or config/ was modified during the test run:" >&2
  diff <(echo "$PRODUCT_SNAPSHOT") <(echo "$PRODUCT_SNAPSHOT_END") >&2 || true
  exit 1
fi
echo "  ✓ PASS: Product source tree remains clean"
