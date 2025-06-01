#!/bin/bash
# run_all_tests.sh - Run all bats test files

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

echo -e "${BLUE}🧪 Running all bats tests for credential management scripts${NC}"
echo "=================================================================="
echo ""

# Check if bats is available
if ! command -v bats &> /dev/null; then
    echo -e "${RED}❌ Error: bats-core is not installed${NC}"
    echo "Please install bats-core first:"
    echo "  brew install bats-core"
    exit 1
fi

# List of test files to run
TEST_FILES=(
    "credmatch.bats"
    "credmatch_basic.bats"
    "credmatch_advanced.bats"
    "store_api_key.bats"
    "store_api_key_advanced.bats"
    "get_api_key.bats"
    "dump_api_keys.bats"
    "test_all_scripts.bats"
    "test_config_manager.bats"
)

# Track results
TOTAL_FILES=0
PASSED_FILES=0
FAILED_FILES=0
declare -a FAILED_TEST_FILES=()

# Run each test file
for test_file in "${TEST_FILES[@]}"; do
    test_path="$SCRIPT_DIR/$test_file"

    if [[ ! -f "$test_path" ]]; then
        echo -e "${YELLOW}⚠️  Warning: Test file not found: $test_file${NC}"
        continue
    fi

    echo -e "${BLUE}Running: $test_file${NC}"
    ((TOTAL_FILES++))

    if bats "$test_path"; then
        echo -e "${GREEN}✅ PASSED: $test_file${NC}"
        ((PASSED_FILES++))
    else
        echo -e "${RED}❌ FAILED: $test_file${NC}"
        FAILED_TEST_FILES+=("$test_file")
        ((FAILED_FILES++))
    fi
    echo ""
done

# Summary
echo "=================================================================="
echo -e "${BLUE}Test Summary:${NC}"
echo "  Total test files: $TOTAL_FILES"
echo -e "  ${GREEN}Passed: $PASSED_FILES${NC}"
echo -e "  ${RED}Failed: $FAILED_FILES${NC}"
echo ""

if [[ $FAILED_FILES -eq 0 ]]; then
    echo -e "${GREEN}🎉 All test files passed!${NC}"
    exit 0
else
    echo -e "${RED}❌ Some test files failed:${NC}"
    for failed_file in "${FAILED_TEST_FILES[@]}"; do
        echo -e "${RED}  - $failed_file${NC}"
    done
    echo ""
    echo -e "${YELLOW}💡 To run a specific test file:${NC}"
    echo "  bats tests/<test_file>.bats"
    echo ""
    echo -e "${YELLOW}💡 To run tests with verbose output:${NC}"
    echo "  bats --verbose-run tests/<test_file>.bats"
    exit 1
fi
