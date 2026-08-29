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

# Track temporary directories for cleanup on exit
CLEANUP_DIRS=()
cleanup() {
  for d in "${CLEANUP_DIRS[@]}"; do
    if [[ -d "$d" ]]; then
      rm -rf "$d"
    fi
  done
}
trap cleanup EXIT

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

# 2.1 Invocation from external working directory
EXTERNAL_TMP="$(mktemp -d)"
CLEANUP_DIRS+=("$EXTERNAL_TMP")

EXT_VERSION="$(cd "$EXTERNAL_TMP" && "$LAUNCHER" --version)"
if [[ "$EXT_VERSION" != *"novim-dev"* ]]; then
  echo "Error: Invocation from external directory failed." >&2
  exit 1
fi
echo "  ✓ PASS: Invocation from external working directory resolves repository root"

# 2.2 Invocation via symlinked launcher
SYMLINK_DIR="$(mktemp -d)"
CLEANUP_DIRS+=("$SYMLINK_DIR")
ln -s "$LAUNCHER" "$SYMLINK_DIR/novim-dev-symlink"

LINK_VERSION="$("$SYMLINK_DIR/novim-dev-symlink" --version)"
if [[ "$LINK_VERSION" != *"novim-dev"* ]]; then
  echo "Error: Invocation via symlink failed." >&2
  exit 1
fi
echo "  ✓ PASS: Invocation through symlink resolves real repository root"

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
"$LAUNCHER" --headless -u "$PROJECT_ROOT/config/nvim/init.lua" -l "$PROJECT_ROOT/tests/test_smoke.lua"
echo "  ✓ PASS: All headless regression smoke tests passed"

echo ""
echo "--- Step 4: Post-Run Artifact and Cleanup Verification ---"

# Verify no leftover test fixtures in /tmp matching smoke test patterns
LEFTOVER_COUNT=0
for leftover in /tmp/*_smoke_git_fixture* /tmp/*_smoke_project_fixture* /tmp/*_smoke_non_git* /tmp/*_smoke_clean_git*; do
  if [[ -e "$leftover" ]]; then
    echo "Warning: Detected uncleaned smoke fixture: $leftover" >&2
    LEFTOVER_COUNT=$((LEFTOVER_COUNT + 1))
    rm -rf "$leftover"
  fi
done

if [[ "$LEFTOVER_COUNT" -gt 0 ]]; then
  echo "Error: $LEFTOVER_COUNT test fixture(s) were not cleaned up." >&2
  exit 1
fi
echo "  ✓ PASS: Zero fixture residue left in temporary directory"

# Verify product source directories were not modified by test execution
PRODUCT_MODS="$(git -C "$PROJECT_ROOT" status --porcelain=v1 -- bin/ config/)"
if [[ -n "$PRODUCT_MODS" ]]; then
  echo "Error: Product code in bin/ or config/ was unexpectedly modified:" >&2
  echo "$PRODUCT_MODS" >&2
  exit 1
fi
echo "  ✓ PASS: Product source tree remains clean"

echo ""
echo "=== All novim-dev Regression Smoke Tests Passed Successfully ==="
exit 0
