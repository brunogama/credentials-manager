#!/bin/bash
#
# security-manager.sh - Core security functions for credential management scripts
# This library implements high-priority security features:
# - File permissions & umask management
# - Secure temporary file handling
# - Enhanced input validation & sanitization
# - Audit logging system

set -euo pipefail

# Constants
readonly AUDIT_LOG_FILE="$HOME/.credmatch/audit.log"
readonly AUDIT_LOG_MAX_SIZE=10485760  # 10MB
readonly AUDIT_LOG_RETENTION_DAYS=90
readonly TEMP_FILES=()

# File Permissions Management
setup_secure_permissions() {
  # Set restrictive umask for new files
  umask 077

  # Function to secure existing files
  secure_file() {
    local file="$1"
    if [[ -f "$file" ]]; then
      chmod 600 "$file" 2>/dev/null || {
        echo "⚠️  Warning: Could not secure permissions for $file" >&2
      }
    fi
  }

  # Function to secure directories
  secure_directory() {
    local dir="$1"
    if [[ -d "$dir" ]]; then
      chmod 700 "$dir" 2>/dev/null || {
        echo "⚠️  Warning: Could not secure permissions for $dir" >&2
      }
    fi
  }
}

# Validate and fix permissions on startup
validate_permissions() {
  local store_dir="$1"
  secure_directory "$store_dir"
  secure_file "$store_dir/credentials.json"
  secure_file "$AUDIT_LOG_FILE"
}

# Secure Temporary File Handling
create_secure_temp() {
  local prefix="${1:-credmatch}"
  local temp_file

  # Create temporary file with secure permissions
  temp_file=$(mktemp -t "${prefix}.XXXXXX") || {
    echo "Error: Failed to create temporary file" >&2
    return 1
  }

  # Set secure permissions immediately
  chmod 600 "$temp_file" || {
    rm -f "$temp_file"
    echo "Error: Failed to secure temporary file" >&2
    return 1
  }

  # Register for cleanup
  register_temp_file "$temp_file"
  echo "$temp_file"
}

# Temporary file registry for cleanup
register_temp_file() {
  TEMP_FILES+=("$1")
}

# Enhanced cleanup function
cleanup_temp_files() {
  for temp_file in "${TEMP_FILES[@]}"; do
    if [[ -f "$temp_file" ]]; then
      # Overwrite with random data before deletion
      dd if=/dev/urandom of="$temp_file" bs=1024 count=1 2>/dev/null || true
      rm -f "$temp_file"
    fi
  done
  TEMP_FILES=()
}

# Input Validation
validate_input() {
  local input="$1"
  local type="$2"
  local max_length="${3:-256}"

  # Check for null/empty input
  if [[ -z "$input" ]]; then
    echo "Error: Input cannot be empty" >&2
    return 1
  fi

  # Check length limits
  if [[ ${#input} -gt $max_length ]]; then
    echo "Error: Input exceeds maximum length of $max_length characters" >&2
    return 1
  fi

  case "$type" in
    "service_name")
      # Service names: alphanumeric, underscore, dash only
      if ! [[ "$input" =~ ^[A-Za-z0-9_-]{1,64}$ ]]; then
        echo "Error: Service name must contain only letters, numbers, underscores, and dashes (max 64 chars)" >&2
        return 1
      fi
      ;;
    "git_url")
      # Git URLs: must start with https:// or git@
      if ! [[ "$input" =~ ^(https://|git@)[A-Za-z0-9._/-]+$ ]]; then
        echo "Error: Invalid git URL format" >&2
        return 1
      fi
      ;;
    "api_key")
      # API keys: check for reasonable patterns
      if [[ ${#input} -lt 8 ]]; then
        echo "Warning: API key seems unusually short" >&2
      fi
      # Check for suspicious patterns
      if echo "$input" | grep -q '[<>\"'\''&;|`]'; then
        echo "Error: API key contains potentially dangerous characters" >&2
        return 1
      fi
      ;;
    "master_password")
      # Master passwords: minimum security requirements
      if [[ ${#input} -lt 8 ]]; then
        echo "Error: Master password must be at least 8 characters" >&2
        return 1
      fi
      ;;
  esac

  return 0
}

# Sanitize input for safe usage
sanitize_input() {
  local input="$1"
  # Remove control characters and normalize whitespace
  echo "$input" | tr -d '\000-\037\177' | tr -s ' '
}

# Audit Logging System
init_audit_log() {
  local log_dir
  log_dir=$(dirname "$AUDIT_LOG_FILE")
  mkdir -p "$log_dir"
  chmod 700 "$log_dir"

  # Create log file if it doesn't exist
  if [[ ! -f "$AUDIT_LOG_FILE" ]]; then
    touch "$AUDIT_LOG_FILE"
    chmod 600 "$AUDIT_LOG_FILE"
  fi
}

# Audit log entry
audit_log() {
  local action="$1"
  local service="$2"
  local status="${3:-SUCCESS}"
  local details="${4:-}"

  local timestamp
  timestamp=$(date -u +"%Y-%m-%d %H:%M:%S UTC")
  local user_info="$USER@$(hostname)"
  local pid="$$"

  # Create log entry (never log sensitive data)
  local log_entry="[$timestamp] PID:$pid USER:$user_info ACTION:$action SERVICE:$service STATUS:$status"
  if [[ -n "$details" ]]; then
    log_entry="$log_entry DETAILS:$details"
  fi

  # Write to log file
  echo "$log_entry" >> "$AUDIT_LOG_FILE" 2>/dev/null || {
    echo "Warning: Failed to write audit log" >&2
  }

  # Check for log rotation
  rotate_audit_log
}

# Log rotation
rotate_audit_log() {
  if [[ -f "$AUDIT_LOG_FILE" ]]; then
    local size
    size=$(stat -f%z "$AUDIT_LOG_FILE" 2>/dev/null || stat -c%s "$AUDIT_LOG_FILE")

    if [[ $size -gt $AUDIT_LOG_MAX_SIZE ]]; then
      local backup="$AUDIT_LOG_FILE.$(date +%Y%m%d_%H%M%S)"
      mv "$AUDIT_LOG_FILE" "$backup"
      touch "$AUDIT_LOG_FILE"
      chmod 600 "$AUDIT_LOG_FILE"

      # Cleanup old backups
      find "$(dirname "$AUDIT_LOG_FILE")" -name "$(basename "$AUDIT_LOG_FILE").*" -mtime +"$AUDIT_LOG_RETENTION_DAYS" -delete
    fi
  fi
}

# Trap cleanup on script exit
trap cleanup_temp_files EXIT INT TERM
