#!/bin/bash
# Comprehensive test suite for all credential management scripts

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Test counters
TESTS_PASSED=0
TESTS_FAILED=0
TOTAL_TESTS=0

# Test result tracking
declare -a FAILED_TESTS=()

# Function to print test results
print_test_result() {
  local test_name="$1"
  local result="$2"
  local details="${3:-}"
  
  ((TOTAL_TESTS++))
  
  if [[ "$result" == "PASS" ]]; then
    echo -e "${GREEN}✅ PASS${NC}: $test_name"
    ((TESTS_PASSED++))
  else
    echo -e "${RED}❌ FAIL${NC}: $test_name"
    if [[ -n "$details" ]]; then
      echo -e "${RED}   Details: $details${NC}"
    fi
    FAILED_TESTS+=("$test_name")
    ((TESTS_FAILED++))
  fi
}

# Function to run a test command and capture result
run_test() {
  local test_name="$1"
  local command="$2"
  local expected_exit_code="${3:-0}"
  
  echo -e "${BLUE}Running: $test_name${NC}"
  
  if eval "$command" >/dev/null 2>&1; then
    local actual_exit_code=0
  else
    local actual_exit_code=$?
  fi
  
  if [[ $actual_exit_code -eq $expected_exit_code ]]; then
    print_test_result "$test_name" "PASS"
  else
    print_test_result "$test_name" "FAIL" "Expected exit code $expected_exit_code, got $actual_exit_code"
  fi
}

# Function to test script syntax
test_script_syntax() {
  local script="$1"
  echo -e "${BLUE}Testing syntax for: $script${NC}"
  
  if bash -n "$script" 2>/dev/null; then
    print_test_result "$script syntax check" "PASS"
  else
    print_test_result "$script syntax check" "FAIL" "Syntax error detected"
  fi
}

# Function to test script help/usage
test_script_help() {
  local script="$1"
  echo -e "${BLUE}Testing help output for: $script${NC}"
  
  # Test --help flag (should exit with code 1 for usage)
  if ./"$script" --help >/dev/null 2>&1; then
    local exit_code=0
  else
    local exit_code=$?
  fi
  
  if [[ $exit_code -eq 1 ]]; then
    print_test_result "$script help output" "PASS"
  else
    print_test_result "$script help output" "FAIL" "Expected exit code 1 for help, got $exit_code"
  fi
}

# Function to test script dependencies
test_script_dependencies() {
  local script="$1"
  echo -e "${BLUE}Testing dependencies for: $script${NC}"
  
  case "$script" in
    "credmatch")
      # Test git and openssl dependencies
      if command -v git >/dev/null 2>&1 && command -v openssl >/dev/null 2>&1; then
        print_test_result "$script dependencies" "PASS"
      else
        print_test_result "$script dependencies" "FAIL" "Missing git or openssl"
      fi
      ;;
    "dump-api-keys"|"get-api-key"|"store-api-key")
      # Test macOS security command
      if [[ "$OSTYPE" == "darwin"* ]] && command -v security >/dev/null 2>&1; then
        print_test_result "$script dependencies" "PASS"
      else
        print_test_result "$script dependencies" "FAIL" "Missing security command or not on macOS"
      fi
      ;;
    *)
      print_test_result "$script dependencies" "PASS" "No specific dependencies"
      ;;
  esac
}

# Function to test credmatch functionality
test_credmatch() {
  echo -e "${YELLOW}=== Testing CredMatch ===${NC}"
  
  # Create a temporary directory for testing
  local test_dir="/tmp/credmatch-test-$$"
  mkdir -p "$test_dir"
  cd "$test_dir"
  
  # Initialize a git repo for testing
  git init >/dev/null 2>&1
  git config user.email "test@example.com" >/dev/null 2>&1
  git config user.name "Test User" >/dev/null 2>&1
  
  # Test init-here command
  if echo | /Users/bruno/Developer/credentials-storage-and-management/credmatch init-here >/dev/null 2>&1; then
    print_test_result "credmatch init-here" "PASS"
  else
    print_test_result "credmatch init-here" "FAIL"
  fi
  
  # Test status command
  if /Users/bruno/Developer/credentials-storage-and-management/credmatch status >/dev/null 2>&1; then
    print_test_result "credmatch status" "PASS"
  else
    print_test_result "credmatch status" "FAIL"
  fi
  
  # Cleanup
  cd /Users/bruno/Developer/credentials-storage-and-management
  rm -rf "$test_dir"
}

# Function to test API key scripts (mock tests since we don't want to modify keychain)
test_api_scripts() {
  echo -e "${YELLOW}=== Testing API Key Scripts ===${NC}"
  
  # Test store-api-key with invalid arguments
  if ./store-api-key >/dev/null 2>&1; then
    print_test_result "store-api-key argument validation" "FAIL" "Should fail with no arguments"
  else
    print_test_result "store-api-key argument validation" "PASS"
  fi
  
  # Test get-api-key with invalid arguments
  if ./get-api-key >/dev/null 2>&1; then
    print_test_result "get-api-key argument validation" "FAIL" "Should fail with no arguments"
  else
    print_test_result "get-api-key argument validation" "PASS"
  fi
  
  # Test dump-api-keys help
  if ./dump-api-keys --help >/dev/null 2>&1; then
    local exit_code=0
  else
    local exit_code=$?
  fi
  
  if [[ $exit_code -eq 0 ]]; then
    print_test_result "dump-api-keys help" "PASS"
  else
    print_test_result "dump-api-keys help" "FAIL"
  fi
}

# Function to test config manager
test_config_manager() {
  echo -e "${YELLOW}=== Testing Config Manager ===${NC}"
  
  # Source the config manager and test basic functionality
  if source lib/config-manager.sh 2>/dev/null; then
    print_test_result "config-manager source" "PASS"
    
    # Test load_security_config function
    if load_security_config >/dev/null 2>&1; then
      print_test_result "config-manager load_security_config" "PASS"
    else
      print_test_result "config-manager load_security_config" "FAIL"
    fi
  else
    print_test_result "config-manager source" "FAIL"
  fi
}

# Main test execution
main() {
  echo -e "${BLUE}🧪 Starting Comprehensive Script Testing${NC}"
  echo -e "${BLUE}=======================================${NC}"
  echo ""
  
  # Change to script directory
  cd /Users/bruno/Developer/credentials-storage-and-management
  
  # Test 1: Script syntax validation
  echo -e "${YELLOW}=== Testing Script Syntax ===${NC}"
  for script in credmatch dump-api-keys get-api-key store-api-key lib/config-manager.sh; do
    test_script_syntax "$script"
  done
  echo ""
  
  # Test 2: Shellcheck validation
  echo -e "${YELLOW}=== Testing Shellcheck Compliance ===${NC}"
  for script in credmatch dump-api-keys get-api-key store-api-key lib/config-manager.sh; do
    if shellcheck "$script" >/dev/null 2>&1; then
      print_test_result "$script shellcheck" "PASS"
    else
      print_test_result "$script shellcheck" "FAIL"
    fi
  done
  echo ""
  
  # Test 3: Script help/usage
  echo -e "${YELLOW}=== Testing Help Output ===${NC}"
  for script in credmatch dump-api-keys get-api-key store-api-key; do
    test_script_help "$script"
  done
  echo ""
  
  # Test 4: Dependencies
  echo -e "${YELLOW}=== Testing Dependencies ===${NC}"
  for script in credmatch dump-api-keys get-api-key store-api-key; do
    test_script_dependencies "$script"
  done
  echo ""
  
  # Test 5: Functional tests
  test_credmatch
  echo ""
  
  test_api_scripts
  echo ""
  
  test_config_manager
  echo ""
  
  # Test 6: File permissions
  echo -e "${YELLOW}=== Testing File Permissions ===${NC}"
  for script in credmatch dump-api-keys get-api-key store-api-key; do
    if [[ -x "$script" ]]; then
      print_test_result "$script executable" "PASS"
    else
      print_test_result "$script executable" "FAIL" "Script is not executable"
    fi
  done
  echo ""
  
  # Final results
  echo -e "${BLUE}���� Test Results Summary${NC}"
  echo -e "${BLUE}======================${NC}"
  echo -e "Total Tests: $TOTAL_TESTS"
  echo -e "${GREEN}Passed: $TESTS_PASSED${NC}"
  echo -e "${RED}Failed: $TESTS_FAILED${NC}"
  
  if [[ $TESTS_FAILED -gt 0 ]]; then
    echo ""
    echo -e "${RED}Failed Tests:${NC}"
    for test in "${FAILED_TESTS[@]}"; do
      echo -e "${RED}  - $test${NC}"
    done
    echo ""
    echo -e "${RED}❌ Some tests failed. Please review the issues above.${NC}"
    exit 1
  else
    echo ""
    echo -e "${GREEN}🎉 All tests passed successfully!${NC}"
    exit 0
  fi
}

# Run main function
main "$@"