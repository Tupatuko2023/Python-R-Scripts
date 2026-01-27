#!/bin/bash
# Ralph runner wrapper for Windows Git Bash
# Ensures jq and claude are in PATH before running ralph.sh
#
# Usage: ./run-ralph.sh [--tool amp|claude] [max_iterations]
#
# This wrapper is needed on Windows because:
# 1. jq installed via winget is not automatically in PATH
# 2. claude installed via npm is in ~/.local/bin which may not be in PATH

set -e

# Add local binary directories to PATH
export PATH="$HOME/bin:$HOME/.local/bin:$PATH"

# Verify prerequisites
echo "Checking prerequisites..."

if ! command -v jq &> /dev/null; then
    echo "ERROR: jq not found in PATH"
    echo "Install with: winget install jqlang.jq"
    echo "Then copy/symlink to ~/bin/: cp \"\$LOCALAPPDATA/Microsoft/WinGet/Packages/jqlang.jq_*/jq.exe\" ~/bin/jq"
    exit 1
fi

if ! command -v claude &> /dev/null && ! command -v amp &> /dev/null; then
    echo "ERROR: Neither claude nor amp found in PATH"
    echo "Install Claude Code: npm i -g @anthropic-ai/claude-code"
    echo "Or install Amp per Amp documentation"
    exit 1
fi

echo "OK: jq=$(jq --version)"
if command -v claude &> /dev/null; then
    echo "OK: claude=$(claude --version 2>&1 | head -1)"
fi
if command -v amp &> /dev/null; then
    echo "OK: amp available"
fi

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo ""
echo "Starting Ralph..."
echo ""

# Run ralph.sh with all arguments passed through
exec bash "$SCRIPT_DIR/ralph.sh" "$@"
