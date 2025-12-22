#!/bin/bash
# Helper script to run R scripts in Docker
# Usage: ./docker-run.sh K11
#        ./docker-run.sh K11 K12 K13  (run multiple)
#        ./docker-run.sh all          (run all K6-K16)

set -e

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd "$SCRIPT_DIR"

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${BLUE}================================${NC}"
echo -e "${BLUE}FOF R Analysis - Docker Runner${NC}"
echo -e "${BLUE}================================${NC}"
echo ""

# Build image if it doesn't exist
if ! docker image inspect fof-r-analysis:latest &> /dev/null; then
    echo -e "${BLUE}Building Docker image (this may take 10-15 minutes)...${NC}"
    docker-compose build
    echo -e "${GREEN}✓ Image built successfully${NC}"
    echo ""
fi

# Function to run a single script
run_script() {
    local script=$1
    echo -e "${BLUE}Running ${script}...${NC}"

    docker-compose run --rm fof-runner \
        Rscript "R-scripts/${script}/${script}.R"

    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✓ ${script} completed successfully${NC}"
    else
        echo -e "${RED}✗ ${script} failed${NC}"
        return 1
    fi
    echo ""
}

# Parse arguments
if [ $# -eq 0 ]; then
    echo "Usage: $0 <script_name> [script_name2 ...]"
    echo "       $0 all"
    echo ""
    echo "Examples:"
    echo "  $0 K11              # Run K11 only"
    echo "  $0 K11 K12 K13      # Run K11, K12, K13"
    echo "  $0 all              # Run all K6-K16"
    echo ""
    exit 1
fi

# Handle "all" option
if [ "$1" = "all" ]; then
    echo -e "${BLUE}Running all scripts (K6-K16)...${NC}"
    echo ""

    for k in {6..16}; do
        run_script "K${k}" || true
    done

    echo -e "${GREEN}All scripts completed${NC}"
    exit 0
fi

# Run specified scripts
for script in "$@"; do
    # Add K prefix if not present
    if [[ ! $script =~ ^K ]]; then
        script="K${script}"
    fi

    run_script "$script"
done

echo -e "${GREEN}Done!${NC}"
