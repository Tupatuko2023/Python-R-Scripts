#!/bin/bash
# Ralph runner wrapper - cross-platform entry point
# Ensures jq and claude/amp are in PATH before running ralph.sh
#
# Usage: ./run-ralph.sh [--tool amp|claude] [max_iterations]
#
# This wrapper handles:
# - Windows: jq from winget, claude from npm global
# - macOS/Linux: standard PATH locations
# - Creates ~/bin if needed and adds it to PATH

set -e

# Color output (if terminal supports it)
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo_ok() { echo -e "${GREEN}OK${NC}: $1"; }
echo_err() { echo -e "${RED}ERROR${NC}: $1"; }
echo_warn() { echo -e "${YELLOW}NOTE${NC}: $1"; }

# Ensure ~/bin exists
mkdir -p "$HOME/bin"

# Add common binary directories to PATH
export PATH="$HOME/bin:$HOME/.local/bin:$PATH"

# Windows-specific: auto-detect WinGet jq location
if [[ "$OSTYPE" == "msys" || "$OSTYPE" == "cygwin" || "$OSTYPE" == "win32" ]]; then
    # Try to find jq in WinGet packages directory
    WINGET_JQ_DIR="$LOCALAPPDATA/Microsoft/WinGet/Packages"
    if [[ -d "$WINGET_JQ_DIR" ]]; then
        JQ_PKG=$(find "$WINGET_JQ_DIR" -maxdepth 1 -type d -name "jqlang.jq_*" 2>/dev/null | head -1)
        if [[ -n "$JQ_PKG" && -f "$JQ_PKG/jq.exe" ]]; then
            export PATH="$JQ_PKG:$PATH"
        fi
    fi
fi

echo "=== Ralph Wrapper - Checking prerequisites ==="
echo ""

# Check jq
JQ_OK=false
if command -v jq &> /dev/null; then
    echo_ok "jq $(jq --version 2>&1)"
    JQ_OK=true
else
    echo_err "jq not found"
    echo ""
    echo "Install jq using ONE of these methods:"
    echo ""
    if [[ "$OSTYPE" == "msys" || "$OSTYPE" == "cygwin" ]]; then
        echo "  Windows (winget + copy to ~/bin):"
        echo "    winget install jqlang.jq"
        echo '    cp "$LOCALAPPDATA/Microsoft/WinGet/Packages/jqlang.jq_"*/jq.exe ~/bin/jq'
        echo ""
        echo "  Windows (chocolatey):"
        echo "    choco install jq"
    elif [[ "$OSTYPE" == "darwin"* ]]; then
        echo "  macOS (Homebrew):"
        echo "    brew install jq"
    else
        echo "  Linux (apt):"
        echo "    sudo apt-get install jq"
        echo ""
        echo "  Linux (yum/dnf):"
        echo "    sudo dnf install jq"
    fi
    echo ""
fi

# Check claude or amp
AGENT_OK=false
AGENT_CMD=""
if command -v claude &> /dev/null; then
    echo_ok "claude $(claude --version 2>&1 | head -1)"
    AGENT_OK=true
    AGENT_CMD="claude"
fi
if command -v amp &> /dev/null; then
    echo_ok "amp available"
    AGENT_OK=true
    [[ -z "$AGENT_CMD" ]] && AGENT_CMD="amp"
fi

if [[ "$AGENT_OK" == "false" ]]; then
    echo_err "Neither claude nor amp found"
    echo ""
    echo "Install ONE of these agent CLIs:"
    echo ""
    echo "  Claude Code (recommended):"
    echo "    npm install -g @anthropic-ai/claude-code"
    echo ""
    echo "  Amp:"
    echo "    See Amp documentation for installation"
    echo ""
fi

# Exit if prerequisites missing
if [[ "$JQ_OK" == "false" || "$AGENT_OK" == "false" ]]; then
    echo ""
    echo "Fix the above issues and run this script again."
    exit 1
fi

echo ""

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(dirname "$(dirname "$SCRIPT_DIR")")"

# Verify prd.json exists
if [[ ! -f "$ROOT_DIR/prd.json" ]]; then
    echo_err "prd.json not found at $ROOT_DIR/prd.json"
    echo "Create a PRD file with at least one user story."
    exit 1
fi

# Show current PRD info
BRANCH=$(jq -r '.branchName // "unknown"' "$ROOT_DIR/prd.json")
STORIES_TODO=$(jq '[.userStories[] | select(.passes == false)] | length' "$ROOT_DIR/prd.json")
STORIES_DONE=$(jq '[.userStories[] | select(.passes == true)] | length' "$ROOT_DIR/prd.json")

echo "PRD: $ROOT_DIR/prd.json"
echo "  Branch: $BRANCH"
echo "  Stories: $STORIES_DONE done, $STORIES_TODO remaining"
echo ""

if [[ "$STORIES_TODO" -eq 0 ]]; then
    echo_warn "No stories with passes:false - Ralph has nothing to do."
    echo "Add stories to prd.json or reset passes:false on existing ones."
    exit 0
fi

echo "Starting Ralph..."
echo "========================================"
echo ""

# Run ralph.sh with all arguments passed through
exec bash "$SCRIPT_DIR/ralph.sh" "$@"
