#!/bin/bash
# test_helper.bash - Common test utilities for bats tests

# Test environment setup
export BATS_TEST_DIRNAME="${BATS_TEST_DIRNAME:-$(dirname "${BASH_SOURCE[0]}")}"
export PROJECT_ROOT="${BATS_TEST_DIRNAME}/.."

# Test data
export TEST_SERVICE_NAME="TEST_API_KEY"
export TEST_API_KEY="test-api-key-12345"
export TEST_USER="${USER:-testuser}"

# Mock keychain directory for testing
export TEST_KEYCHAIN_DIR="${BATS_TMPDIR}/test_keychain"

# Colors for test output
export RED='\033[0;31m'
export GREEN='\033[0;32m'
export YELLOW='\033[1;33m'
export NC='\033[0m'

# Setup function called before each test
setup() {
  # Create temporary directories
  mkdir -p "${TEST_KEYCHAIN_DIR}"

  # Set up test environment variables
  export TMPDIR="${BATS_TMPDIR}"
  export HOME="${BATS_TMPDIR}/home"
  mkdir -p "${HOME}"

  # Create fixtures directory if it doesn't exist
  mkdir -p "${BATS_TEST_DIRNAME}/fixtures"

  # Create mock security command
  create_mock_security

  # Set up PATH to include fixtures directory with mock commands
  export PATH="${BATS_TEST_DIRNAME}/fixtures:${PATH}"
}

# Teardown function called after each test
teardown() {
  # Clean up test files
  rm -rf "${TEST_KEYCHAIN_DIR}"
  rm -rf "${BATS_TMPDIR}/home"

  # Remove any test files from project directory
  rm -f "${PROJECT_ROOT}/.credmatch-store/test_*"
  rm -rf "${PROJECT_ROOT}/.credmatch-store-test"
}

# Helper function to create mock security command
create_mock_security() {
  local mock_file="${BATS_TEST_DIRNAME}/fixtures/security"
  cat > "${mock_file}" << 'EOF'
#!/bin/bash
# Mock security command for testing

case "$1" in
  "find-generic-password")
    # Parse arguments
    service=""
    account=""
    password_only=false

    while [[ $# -gt 0 ]]; do
      case "$1" in
        -s) service="$2"; shift 2 ;;
        -a) account="$2"; shift 2 ;;
        -w) password_only=true; shift ;;
        *) shift ;;
      esac
    done

    # Check if test key exists
    if [[ "$service" == "TEST_API_KEY" ]]; then
      if [[ "$password_only" == "true" ]]; then
        echo "test-api-key-12345"
      else
        echo "password: \"test-api-key-12345\""
      fi
      exit 0
    elif [[ "$service" == "SERVICEA_API_KEY" ]]; then
      if [[ "$password_only" == "true" ]]; then
        echo "servicea-key-67890"
      else
        echo "password: \"servicea-key-67890\""
      fi
      exit 0
    elif [[ "$service" == "AWS_API_KEY" ]]; then
      if [[ "$password_only" == "true" ]]; then
        echo "aws-key-abcdef"
      else
        echo "password: \"aws-key-abcdef\""
      fi
      exit 0
    else
      echo "security: SecKeychainSearchCopyNext: The specified item could not be found in the keychain." >&2
      exit 44
    fi
    ;;
  "add-generic-password")
    # Mock successful addition
    exit 0
    ;;
  "dump-keychain")
    # Mock keychain dump output
    cat << 'DUMP_EOF'
keychain: "/Users/testuser/Library/Keychains/login.keychain-db"
version: 512
class: 0x00000010
attributes:
    0x00000007 <blob>="TEST_API_KEY"
    "acct"<blob>="testuser"
    "svce"<blob>="TEST_API_KEY"
data:
"test-api-key-12345"

class: 0x00000010
attributes:
    0x00000007 <blob>="SERVICEA_API_KEY"
    "acct"<blob>="testuser"
    "svce"<blob>="SERVICEA_API_KEY"
data:
"servicea-key-67890"

class: 0x00000010
attributes:
    0x00000007 <blob>="AWS_API_KEY"
    "acct"<blob>="testuser"
    "svce"<blob>="AWS_API_KEY"
data:
"aws-key-abcdef"
DUMP_EOF
    ;;
  *)
    echo "Mock security command: unknown option $1" >&2
    exit 1
    ;;
esac
EOF
  chmod +x "${mock_file}"
}

# Helper function to create test git repository
create_test_git_repo() {
  local repo_dir="$1"
  mkdir -p "${repo_dir}"
  cd "${repo_dir}" || return 1
  git init --quiet
  git config user.email "test@example.com"
  git config user.name "Test User"
  echo "# Test Repository" > README.md
  git add README.md
  git commit -m "Initial commit" --quiet
  cd - > /dev/null || return 1
}

# Helper function to check if script exists and is executable
assert_script_exists() {
  local script_path="$1"
  [[ -f "$script_path" ]] || {
    echo "Script not found: $script_path" >&2
    return 1
  }
  [[ -x "$script_path" ]] || {
    echo "Script not executable: $script_path" >&2
    return 1
  }
}

# Helper function to run script with timeout
run_script_with_timeout() {
  local timeout="$1"
  local script="$2"
  shift 2
  timeout "$timeout" "$script" "$@"
}

# Helper function to check script syntax
check_script_syntax() {
  local script_path="$1"
  bash -n "$script_path"
}

# Helper function to run shellcheck on script
check_script_shellcheck() {
  local script_path="$1"
  if command -v shellcheck >/dev/null 2>&1; then
    # For test scripts, ignore informational warnings about sourcing and unreachable code
    if [[ "$script_path" =~ test.*\.sh$ ]]; then
      shellcheck -e SC1091,SC2317 "$script_path"
    else
      shellcheck "$script_path"
    fi
  else
    echo "shellcheck not available, skipping check" >&2
    return 0
  fi
}

# Helper function to run command and capture both stdout and stderr separately
run_with_stderr() {
  local stdout_file="${BATS_TMPDIR}/stdout.$$"
  local stderr_file="${BATS_TMPDIR}/stderr.$$"

  # Run the command and capture stdout and stderr separately
  "$@" >"$stdout_file" 2>"$stderr_file"
  status=$?

  # Read the captured output
  output=$(<"$stdout_file")
  stderr=$(<"$stderr_file")

  # Convert output to lines array (compatible with older bash versions)
  lines=()
  while IFS= read -r line; do
    lines+=("$line")
  done < "$stdout_file"

  # Clean up temporary files
  rm -f "$stdout_file" "$stderr_file"

  return $status
}
