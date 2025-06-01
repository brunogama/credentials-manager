#!/bin/bash
#
# validation.sh - Enhanced API key validation module
# Provides entropy checking, pattern validation, and backward compatibility
#
# Functions:
#   validate_service_name <name>                    - Validate service name format
#   validate_api_key_entropy <key> [min_entropy]    - Check API key entropy
#   validate_api_key_patterns <key>                 - Check for weak patterns
#   validate_api_key_enhanced <key> [min_length]    - Comprehensive validation
#
# Return codes:
#   0 - Valid/Strong
#   1 - Invalid/Weak
#   2 - Warning (valid but could be stronger)

# Validate service name format (backward compatibility)
validate_service_name() {
  local service_name="$1"

  # Check if empty
  if [[ -z "$service_name" ]]; then
    return 1
  fi

  # Check format: alphanumeric, underscore, dash only
  if ! [[ "$service_name" =~ ^[A-Za-z0-9_-]+$ ]]; then
    return 1
  fi

  return 0
}

# Calculate entropy of a string (improved approach)
calculate_entropy() {
  local text="$1"
  local length=${#text}

  if [[ $length -eq 0 ]]; then
    echo "0"
    return
  fi

  # Count unique characters
  local unique_chars=$(echo "$text" | grep -o . | sort -u | wc -l)

  # Determine character set size based on actual characters used
  local charset_size=0
  local charset_types=0
  if [[ "$text" =~ [a-z] ]]; then ((charset_size += 26)); ((charset_types++)); fi
  if [[ "$text" =~ [A-Z] ]]; then ((charset_size += 26)); ((charset_types++)); fi
  if [[ "$text" =~ [0-9] ]]; then ((charset_size += 10)); ((charset_types++)); fi
  if [[ "$text" =~ [^a-zA-Z0-9] ]]; then ((charset_size += 32)); ((charset_types++)); fi  # Special chars

  # Minimum charset size
  if [[ $charset_size -lt 10 ]]; then charset_size=10; fi

  # Check for sequential patterns (penalty)
  local sequential_penalty=1.0
  local lower_text=$(echo "$text" | tr '[:upper:]' '[:lower:]')
  if [[ "$lower_text" =~ abcdefghijklmnop ]] || \
     [[ "$lower_text" =~ abcdefghijklm ]] || \
     [[ "$text" =~ 123456789 ]] || \
     [[ "$text" =~ 987654321 ]]; then
    sequential_penalty=0.3
  fi

  # Calculate entropy based on character diversity and length
  # Higher weight for good diversity and reasonable length
  local diversity_ratio=$(echo "scale=3; $unique_chars / $length" | bc -l 2>/dev/null || echo "0.5")
  local length_bonus=$(echo "scale=3; if ($length >= 16) 1.2 else if ($length >= 12) 1.0 else 0.8" | bc -l 2>/dev/null || echo "1.0")
  local charset_bonus=$(echo "scale=3; if ($charset_size >= 60) 1.3 else if ($charset_size >= 36) 1.1 else 1.0" | bc -l 2>/dev/null || echo "1.0")
  local charset_type_bonus=$(echo "scale=3; if ($charset_types >= 3) 1.2 else if ($charset_types >= 2) 1.0 else 0.6" | bc -l 2>/dev/null || echo "1.0")

  # Improved entropy calculation with sequential penalty
  local base_entropy=$(echo "scale=3; $diversity_ratio * 4.0" | bc -l 2>/dev/null || echo "2.0")
  local entropy=$(echo "scale=2; $base_entropy * $length_bonus * $charset_bonus * $charset_type_bonus * $sequential_penalty" | bc -l 2>/dev/null || echo "3.0")

  echo "$entropy"
}

# Validate API key entropy
validate_api_key_entropy() {
  local api_key="$1"
  local min_entropy="${2:-3.5}"  # Default minimum entropy threshold

  # Check if key is too short
  if [[ ${#api_key} -lt 8 ]]; then
    return 1
  fi

  # Check if bc is available for entropy calculation
  if ! command -v bc &> /dev/null; then
    # Fallback: simple character diversity check
    local unique_chars=$(echo "$api_key" | grep -o . | sort -u | wc -l)
    local total_chars=${#api_key}
    local diversity_ratio=$(( unique_chars * 100 / total_chars ))

    # Require at least 50% character diversity
    if [[ $diversity_ratio -lt 50 ]]; then
      return 1
    fi
    return 0
  fi

  # Calculate actual entropy
  local entropy
  entropy=$(calculate_entropy "$api_key")

  # Compare with minimum threshold
  if (( $(echo "$entropy < $min_entropy" | bc -l) )); then
    return 1
  fi

  return 0
}

# Validate API key patterns
validate_api_key_patterns() {
  local api_key="$1"

  # Check minimum length
  if [[ ${#api_key} -lt 8 ]]; then
    return 1
  fi

  # Check for repeated characters (more than 4 consecutive)
  if [[ "$api_key" =~ (.)\1{4,} ]]; then
    return 1
  fi

  # Check for simple sequential patterns
  local lower_key=$(echo "$api_key" | tr '[:upper:]' '[:lower:]')  # Convert to lowercase

    # Sequential alphabet (forward) - only check for long sequences
  if [[ "$lower_key" =~ abcdefghijklmnopqrstuvwxyz ]] || \
     [[ "$lower_key" =~ abcdefghijklmnopqrstuvw ]]; then
    return 1
  fi

  # Sequential alphabet (reverse) - only check for long sequences
  if [[ "$lower_key" =~ zyxwvutsrqponmlkjihgfedcba ]] || \
     [[ "$lower_key" =~ zyxwvutsrqponmlkjihgfedc ]]; then
    return 1
  fi

  # Sequential numbers
  if [[ "$api_key" =~ 123456789 ]] || \
     [[ "$api_key" =~ 987654321 ]] || \
     [[ "$api_key" =~ 0123456789 ]]; then
    return 1
  fi

  # Common keyboard patterns (full rows only)
  if [[ "$lower_key" =~ qwertyuiopasdfghjklzxcvbnm ]] || \
     [[ "$lower_key" =~ qwertyuiop ]] || \
     [[ "$lower_key" =~ asdfghjkl ]] || \
     [[ "$lower_key" =~ zxcvbnm ]]; then
    return 1
  fi

  # Simple alternating patterns
  if [[ "$api_key" =~ ^(..)\1{4,}$ ]] || \
     [[ "$api_key" =~ ^(.)\1(.)\2{4,}$ ]] || \
     [[ "$api_key" =~ ^(.)(.)\1\2\1\2\1\2 ]]; then
    return 1
  fi

  # Check for simple two-character alternating patterns (ab)+
  local pattern_check=""
  if [[ ${#api_key} -ge 8 ]]; then
    local first_two="${api_key:0:2}"
    local repeated_pattern=""
    local i
    for ((i=0; i<${#api_key}; i+=2)); do
      repeated_pattern+="$first_two"
    done
    # Trim to match original length
    repeated_pattern="${repeated_pattern:0:${#api_key}}"
    if [[ "$api_key" == "$repeated_pattern" ]]; then
      return 1
    fi
  fi

  # Check for too many repeated character groups
  local repeated_groups=0
  local i
  for ((i=0; i<${#api_key}-2; i++)); do
    local char="${api_key:$i:1}"
    local next_char="${api_key:$((i+1)):1}"
    local next_next_char="${api_key:$((i+2)):1}"

    if [[ "$char" == "$next_char" && "$char" == "$next_next_char" ]]; then
      ((repeated_groups++))
    fi
  done

  if [[ $repeated_groups -gt 2 ]]; then
    return 1
  fi

  return 0
}

# Enhanced API key validation (comprehensive)
validate_api_key_enhanced() {
  local api_key="$1"
  local min_length="${2:-8}"  # Default minimum length

  # Basic checks
  if [[ -z "$api_key" ]]; then
    return 1
  fi

  if [[ ${#api_key} -lt $min_length ]]; then
    return 1
  fi

  # For backward compatibility, first check if it's a simple but valid key
  if [[ ${#api_key} -ge $min_length ]] && [[ "$api_key" =~ ^[a-zA-Z0-9]+$ ]]; then
    # Simple alphanumeric key, long enough
    # Check for extremely weak patterns that should still be rejected
    if [[ "$api_key" =~ (.)\1{7,} ]] || \
       [[ "$api_key" =~ ^0+$ ]] || \
       [[ "$api_key" =~ ^1+$ ]] || \
       [[ "$api_key" =~ ^a+$ ]] || \
       [[ "$api_key" =~ ^A+$ ]] || \
       [[ "$api_key" =~ ^[0-9]+$ ]] || \
       [[ "$api_key" =~ ^[a-z]+$ ]] || \
       [[ "$api_key" =~ ^[A-Z]+$ ]]; then
      return 1
    fi

    # For simple keys that pass basic validation but could be stronger
    if [[ ${#api_key} -lt 16 ]] || \
       [[ ! "$api_key" =~ [A-Z] ]] || \
       [[ ! "$api_key" =~ [0-9] ]]; then
      return 2  # Warning: acceptable but could be stronger
    fi
    return 0  # Simple but valid key
  fi

  # For non-simple keys or keys that passed simple validation
  local entropy
  entropy=$(calculate_entropy "$api_key")

  # Strong key criteria:
  # 1. High entropy (>= 3.5)
  # 2. Good length (>= 16)
  # 3. Mixed character types
  # 4. No weak patterns
  if (( $(echo "$entropy >= 3.5" | bc -l) )) && \
     [[ ${#api_key} -ge 16 ]] && \
     [[ "$api_key" =~ [A-Z] ]] && \
     [[ "$api_key" =~ [a-z] ]] && \
     [[ "$api_key" =~ [0-9] ]]; then
    # Check if patterns are good (validate_api_key_patterns returns 0 for good patterns)
    if validate_api_key_patterns "$api_key"; then
      return 0  # Strong key
    fi
  fi

  # Check for weak patterns that should be rejected
  if [[ "$api_key" =~ (.)\1{4,} ]] || \         # 5+ repeated characters
     [[ "$api_key" =~ ^[a-zA-Z]+$ ]] || \       # Only letters
     [[ "$api_key" =~ ^[0-9]+$ ]] || \          # Only numbers
     [[ "$api_key" =~ 123456789 ]] || \         # Sequential numbers
     [[ "$api_key" =~ 987654321 ]] || \         # Reverse sequential numbers
     [[ "$api_key" =~ abcdefghijklmnop ]] || \  # Sequential letters
     [[ "$api_key" =~ ABCDEFGHIJKLMNOP ]]; then # Sequential uppercase letters
    return 1  # Weak key
  fi

  # Key is acceptable but could be stronger
  return 2
}
