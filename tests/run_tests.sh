#!/bin/bash
# tests/run_tests.sh - Run novim-dev test suite
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd -P)"

echo "Running tests using: $PROJECT_ROOT/bin/novim-dev"
"$PROJECT_ROOT/bin/novim-dev" --headless -u "$PROJECT_ROOT/config/nvim/init.lua" -l "$PROJECT_ROOT/tests/test_workbench.lua"
