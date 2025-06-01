# Technical Specifications (SPECS)
## Security Enhancement Implementation Details

### Document Information
- **Version**: 1.0
- **Date**: 2024-12-19
- **Status**: Draft
- **Related**: [PDR.md](./PDR.md)

---

## 🔥 High Priority Specifications

### File Permissions Management
**Reference**: [PDR.md - HPR-001](./PDR.md#hpr-001-file-permissions--umask-management)

#### Implementation Details
```bash
# Add to all scripts at the beginning
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
    local store_dir=$(get_store_dir)
    secure_directory "$store_dir"
    secure_file "$store_dir/$CREDENTIALS_FILE"
    secure_file "$HOME/.credmatch/audit.log"
}
```

#### Integration Points
- **credmatch**: Secure credential store directory and files
- **store-api-key**: Validate keychain access permissions
- **dump-api-keys**: Secure output file permissions
- **get-api-key**: No file operations, minimal impact

#### Testing
```bash
# Test file creation permissions
test_file_permissions() {
    local test_file=$(mktemp)
    local perms=$(stat -f "%A" "$test_file" 2>/dev/null || stat -c "%a" "$test_file")
    [[ "$perms" == "600" ]] || echo "FAIL: Incorrect permissions $perms"
    rm -f "$test_file"
}
```

---

### Secure Temporary Files
**Reference**: [PDR.md - HPR-002](./PDR.md#hpr-002-secure-temporary-file-handling)

#### Implementation Details
```bash
# Secure temporary file creation
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
TEMP_FILES=()
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
```

#### Integration Points
- **credmatch**: Git operations, encryption/decryption buffers
- **store-api-key**: Keychain import operations
- **dump-api-keys**: Output file generation
- **get-api-key**: Minimal temporary file usage

---

### Input Validation
**Reference**: [PDR.md - HPR-003](./PDR.md#hpr-003-enhanced-input-validation--sanitization)

#### Implementation Details
```bash
# Comprehensive input validation
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
            if [[ "$input" =~ [<>\"\'&;|`] ]]; then
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
```

---

### Audit Logging
**Reference**: [PDR.md - HPR-004](./PDR.md#hpr-004-audit-logging-system)

#### Implementation Details
```bash
# Audit logging system
AUDIT_LOG_FILE="$HOME/.credmatch/audit.log"
AUDIT_LOG_MAX_SIZE=10485760  # 10MB
AUDIT_LOG_RETENTION_DAYS=90

# Initialize audit logging
init_audit_log() {
    local log_dir=$(dirname "$AUDIT_LOG_FILE")
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

    local timestamp=$(date -u +"%Y-%m-%d %H:%M:%S UTC")
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
        local size=$(stat -f%z "$AUDIT_LOG_FILE" 2>/dev/null || stat -c%s "$AUDIT_LOG_FILE" 2>/dev/null || echo 0)
        if [[ $size -gt $AUDIT_LOG_MAX_SIZE ]]; then
            mv "$AUDIT_LOG_FILE" "${AUDIT_LOG_FILE}.$(date +%Y%m%d-%H%M%S)"
            touch "$AUDIT_LOG_FILE"
            chmod 600 "$AUDIT_LOG_FILE"
        fi
    fi
}
```

---

## 🛡️ Medium Priority Specifications

### Environment Validation
**Reference**: [PDR.md - MPR-001](./PDR.md#mpr-001-environment-security-validation)

#### Implementation Details
```bash
# Environment security validation
check_secure_environment() {
    local warnings=()

    # Check for SSH connection
    if [[ -n "$SSH_CONNECTION" || -n "$SSH_CLIENT" ]]; then
        warnings+=("Running over SSH connection - ensure secure tunnel")
    fi

    # Check terminal type
    case "$TERM_PROGRAM" in
        "vscode")
            warnings+=("Running in VS Code terminal - ensure workspace security")
            ;;
        "iTerm.app")
            # Check for session recording
            if pgrep -f "screen.*record" >/dev/null 2>&1; then
                warnings+=("Screen recording may be active")
            fi
            ;;
    esac

    # Check for tmux/screen sessions
    if [[ -n "$TMUX" || -n "$STY" ]]; then
        warnings+=("Running in tmux/screen session - verify session security")
    fi

    # Display warnings
    if [[ ${#warnings[@]} -gt 0 ]]; then
        echo "🔒 ENVIRONMENT SECURITY WARNINGS:" >&2
        for warning in "${warnings[@]}"; do
            echo "   • $warning" >&2
        done
        echo "" >&2
    fi
}
```

### Git Security
**Reference**: [PDR.md - MPR-002](./PDR.md#mpr-002-git-security-enhancements)

#### Implementation Details
```bash
# Git security configuration
configure_git_security() {
    local repo_dir="$1"

    cd "$repo_dir" || return 1

    # Enable commit signing if GPG is available
    if command -v gpg >/dev/null 2>&1; then
        git config --local commit.gpgsign true 2>/dev/null || true
    fi

    # Force HTTPS for security
    git config --local url."https://github.com/".insteadOf "git@github.com:" 2>/dev/null || true
    git config --local url."https://".insteadOf "git://" 2>/dev/null || true

    # SSL verification
    git config --local http.sslVerify true 2>/dev/null || true

    # Secure transfer protocols
    git config --local transfer.fsckObjects true 2>/dev/null || true
    git config --local receive.fsckObjects true 2>/dev/null || true
    git config --local fetch.fsckObjects true 2>/dev/null || true
}
```

### Session Timeout
**Reference**: [PDR.md - MPR-003](./PDR.md#mpr-003-session-timeout--auto-cleanup)

#### Implementation Details
```bash
# Session timeout management
SESSION_TIMEOUT=1800  # 30 minutes default
SESSION_PID_FILE="/tmp/.credmatch_session_$$"

setup_session_timeout() {
    local timeout="${1:-$SESSION_TIMEOUT}"

    # Background timeout process
    (
        sleep "$timeout"
        if [[ -f "$SESSION_PID_FILE" ]]; then
            echo "🔒 Session timeout reached - clearing sensitive data" >&2
            cleanup_sensitive_vars
            rm -f "$SESSION_PID_FILE"
        fi
    ) &

    # Store timeout PID
    echo $! > "$SESSION_PID_FILE"
}

# Cancel timeout on normal exit
cancel_session_timeout() {
    if [[ -f "$SESSION_PID_FILE" ]]; then
        local timeout_pid=$(cat "$SESSION_PID_FILE")
        kill "$timeout_pid" 2>/dev/null || true
        rm -f "$SESSION_PID_FILE"
    fi
}
```

### Keychain Security
**Reference**: [PDR.md - MPR-004](./PDR.md#mpr-004-enhanced-keychain-security)

#### Implementation Details
```bash
# Enhanced keychain security for macOS
configure_keychain_security() {
    # Set keychain to lock after 1 hour of inactivity
    security set-keychain-settings -t 3600 -l ~/Library/Keychains/login.keychain 2>/dev/null || true

    # Verify keychain integrity
    security verify-cert ~/Library/Keychains/login.keychain 2>/dev/null || {
        echo "Warning: Keychain integrity check failed" >&2
    }
}

# Keychain access validation
validate_keychain_access() {
    local service="$1"

    # Test keychain access without retrieving actual data
    if ! security find-generic-password -s "$service" >/dev/null 2>&1; then
        echo "Warning: Keychain access may require authentication" >&2
        return 1
    fi

    return 0
}
```

---

## 🔧 Advanced Feature Specifications

### HSM Support
**Reference**: [PDR.md - ASF-001](./PDR.md#asf-001-hardware-security-module-hsm-support)

#### Implementation Details
```bash
# HSM detection and integration
detect_hsm() {
    local hsm_available=false

    # Check for PKCS#11 tools
    if command -v pkcs11-tool >/dev/null 2>&1; then
        # List available tokens
        if pkcs11-tool --list-tokens 2>/dev/null | grep -q "Token"; then
            hsm_available=true
            echo "🔐 Hardware Security Module detected" >&2
        fi
    fi

    # Check for macOS Secure Enclave
    if [[ "$OSTYPE" == "darwin"* ]] && command -v security >/dev/null 2>&1; then
        if security list-keychains | grep -q "SecureEnclave"; then
            hsm_available=true
            echo "🔐 Secure Enclave available" >&2
        fi
    fi

    echo "$hsm_available"
}
```

### Biometric Authentication
**Reference**: [PDR.md - ASF-002](./PDR.md#asf-002-biometric-authentication)

#### Implementation Details
```bash
# Biometric authentication for macOS Touch ID
biometric_auth() {
    local service="$1"
    local reason="Access credential for $service"

    # Check if Touch ID is available
    if ! bioutil -r >/dev/null 2>&1; then
        return 1  # Biometric not available
    fi

    # Attempt biometric authentication
    if bioutil -p -r "$reason" >/dev/null 2>&1; then
        return 0  # Success
    else
        return 1  # Failed or cancelled
    fi
}
```

### Network Security
**Reference**: [PDR.md - ASF-003](./PDR.md#asf-003-network-security-validation)

#### Implementation Details
```bash
# Network security validation
validate_network_security() {
    local warnings=()

    # Check for VPN connection
    if ! pgrep -f "openvpn\|wireguard" >/dev/null 2>&1; then
        # Check for other VPN indicators
        if ! ifconfig | grep -q "tun\|tap"; then
            warnings+=("No VPN detected - consider using VPN for remote operations")
        fi
    fi

    # DNS security check
    if command -v dig >/dev/null 2>&1; then
        local dns_test=$(dig +short @1.1.1.1 cloudflare.com 2>/dev/null | head -1)
        if [[ -z "$dns_test" ]]; then
            warnings+=("DNS resolution issues detected")
        fi
    fi

    # Display network warnings
    if [[ ${#warnings[@]} -gt 0 ]]; then
        echo "🌐 NETWORK SECURITY WARNINGS:" >&2
        for warning in "${warnings[@]}"; do
            echo "   • $warning" >&2
        done
        echo "" >&2
    fi
}
```

---

## 📋 Configuration & Setup Specifications

### Configuration Management
**Reference**: [PDR.md - CSR-001](./PDR.md#csr-001-security-configuration-management)

#### Configuration File Format
```bash
# ~/.credmatch/security.conf
# Security configuration for credential management scripts

# File permissions
UMASK=077
FILE_PERMISSIONS=600
DIR_PERMISSIONS=700

# Session management
SESSION_TIMEOUT=1800
AUTO_CLEANUP=true

# Audit logging
AUDIT_LOGGING=true
AUDIT_LOG_RETENTION_DAYS=90
AUDIT_LOG_MAX_SIZE=10485760

# Environment security
REQUIRE_SECURE_ENVIRONMENT=false
WARN_SSH_CONNECTIONS=true
WARN_SCREEN_RECORDING=true

# Network security
REQUIRE_VPN=false
VERIFY_SSL_CERTS=true
FORCE_HTTPS=true

# Advanced features
ENABLE_HSM=false
ENABLE_BIOMETRIC=false
ENABLE_GPG_SIGNING=true
```

#### Configuration Loading
```bash
# Load security configuration
load_security_config() {
    local config_file="$HOME/.credmatch/security.conf"

    # Set defaults
    UMASK=077
    SESSION_TIMEOUT=1800
    AUDIT_LOGGING=true

    # Load configuration if exists
    if [[ -f "$config_file" ]]; then
        # Validate config file permissions
        local perms=$(stat -f "%A" "$config_file" 2>/dev/null || stat -c "%a" "$config_file" 2>/dev/null)
        if [[ "$perms" != "600" ]]; then
            echo "Warning: Configuration file has insecure permissions" >&2
            chmod 600 "$config_file"
        fi

        # Source configuration
        source "$config_file"
    fi
}
```

### Installation Security
**Reference**: [PDR.md - CSR-002](./PDR.md#csr-002-installation-security-script)

#### Setup Script
```bash
#!/bin/bash
# setup-security.sh - Security setup and validation

setup_credmatch_security() {
    echo "🔒 Setting up credential management security..."

    # Create secure directories
    mkdir -p "$HOME/.credmatch"
    chmod 700 "$HOME/.credmatch"

    # Set script permissions
    for script in credmatch store-api-key dump-api-keys get-api-key; do
        if [[ -f "$script" ]]; then
            chmod 755 "$script"
            echo "✓ Secured $script"
        fi
    done

    # Create default configuration
    create_default_config

    # Validate environment
    validate_security_environment

    echo "✅ Security setup complete"
}
```

### Backup Recovery
**Reference**: [PDR.md - CSR-003](./PDR.md#csr-003-backup--recovery-security)

#### Backup Implementation
```bash
# Secure backup creation
create_secure_backup() {
    local backup_dir="$HOME/.credmatch/backups"
    local timestamp=$(date +%Y%m%d-%H%M%S)
    local backup_file="$backup_dir/credmatch-backup-$timestamp.tar.gz.enc"

    mkdir -p "$backup_dir"
    chmod 700 "$backup_dir"

    # Create encrypted backup
    tar -czf - .credmatch-store 2>/dev/null | \
    openssl enc -aes-256-cbc -pbkdf2 -out "$backup_file" || {
        echo "Error: Backup creation failed" >&2
        return 1
    }

    chmod 600 "$backup_file"
    echo "✅ Backup created: $backup_file"
}

# Secure backup restoration
restore_secure_backup() {
    local backup_file="$1"

    if [[ ! -f "$backup_file" ]]; then
        echo "Error: Backup file not found" >&2
        return 1
    fi

    # Decrypt and restore
    openssl enc -aes-256-cbc -d -pbkdf2 -in "$backup_file" | \
    tar -xzf - || {
        echo "Error: Backup restoration failed" >&2
        return 1
    }

    echo "✅ Backup restored successfully"
}
```

---

## 🧪 Testing Specifications

### Security Test Suite
```bash
# Security validation tests
run_security_tests() {
    echo "🧪 Running security test suite..."

    test_file_permissions
    test_input_validation
    test_audit_logging
    test_environment_detection
    test_cleanup_functions

    echo "✅ Security tests complete"
}

test_file_permissions() {
    echo "Testing file permissions..."
    # Implementation details for permission testing
}

test_input_validation() {
    echo "Testing input validation..."
    # Implementation details for input validation testing
}
```

---

## 📚 Integration Guidelines

### Script Integration Pattern
```bash
# Standard security integration pattern for all scripts
initialize_security() {
    load_security_config
    setup_secure_permissions
    init_audit_log
    check_secure_environment
    setup_session_timeout

    # Script-specific security setup
    case "$(basename "$0")" in
        "credmatch")
            configure_git_security
            ;;
        "store-api-key"|"get-api-key")
            configure_keychain_security
            ;;
    esac
}

# Call at script start
initialize_security
```

---

# Reminders

- Every script created must be tested
- Every script created must pass shellcheck check

---
*This specification document provides detailed implementation guidance for all security enhancements outlined in the PDR. Each specification includes code examples, integration points, and testing considerations.*
