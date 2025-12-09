#!/bin/bash

# SAP ABAP Hardware Key Automation Script
# Automates the generation and installation of hardware keys for SAP ABAP system
# Usage: ./scripts/setup-hwkey.sh [generate|install|verify|status]

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
HWKEY_CONFIG="${PROJECT_DIR}/config/hwkey.conf"
HWKEY_DIR="${PROJECT_DIR}/config/hwkeys"
CONTAINER_NAME="${CONTAINER_NAME:-abap-server}"

# Color output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1" >&2
}

# Initialize hardware key directory
init_hwkey_dir() {
    if [ ! -d "$HWKEY_DIR" ]; then
        log_info "Creating hardware key directory: $HWKEY_DIR"
        mkdir -p "$HWKEY_DIR"
        chmod 700 "$HWKEY_DIR"
        log_success "Hardware key directory created"
    fi
}

# Create default hardware key configuration
create_hwkey_config() {
    if [ ! -f "$HWKEY_CONFIG" ]; then
        log_info "Creating hardware key configuration template"
        cat > "$HWKEY_CONFIG" << 'EOF'
# SAP ABAP Hardware Key Configuration
# Last generated: $(date)

# System Information
SID=NPL
SYSTEM_NUMBER=00
HOST_NAME=sapdevboxes
IP_ADDRESS=localhost

# Installation Parameters
DATABASE_USER=sapadm
COMPONENT=
KERNEL_RELEASE=
DB_CONNECT_STRING=

# Security Settings
LICENSE_KEY_PATH=/usr/sap/npl/SYS/etc/license
BACKUP_KEY_PATH=/usr/sap/npl/backup/license
ENCRYPTED_KEY=false

# Automatic Generation Settings
AUTO_RENEW=true
RENEW_BEFORE_EXPIRY_DAYS=30
MAX_RETRIES=3
RETRY_INTERVAL_SECONDS=10
EOF
        chmod 600 "$HWKEY_CONFIG"
        log_success "Hardware key configuration created at $HWKEY_CONFIG"
    else
        log_warning "Hardware key configuration already exists"
    fi
}

# Generate hardware key
generate_hwkey() {
    init_hwkey_dir
    
    log_info "Generating hardware key for SAP system..."
    
    local hwkey_file="${HWKEY_DIR}/hwkey_$(date +%Y%m%d_%H%M%S).key"
    local temp_file="${HWKEY_DIR}/.hwkey_temp"
    
    # Gather system information
    local sid="NPL"
    local hostname=$(hostname)
    local timestamp=$(date +%s)
    
    # Generate hardware key (format: SAP proprietary)
    # Using SHA256 of system identifiers as demonstration
    local hwkey_hash=$(echo "${sid}-${hostname}-${timestamp}" | sha256sum | cut -d' ' -f1)
    
    # Create 4-part SAP license key format (simplified)
    local hwkey_formatted="XXXXXX-XXXXXX-XXXXXX-XXXXXX"
    
    # Write to temporary file
    cat > "$temp_file" << EOF
# SAP ABAP Hardware Key
# Generated: $(date)
# System: $sid
# Hostname: $hostname

HW_KEY=$hwkey_hash
HW_KEY_FORMATTED=$hwkey_formatted
GENERATED_TIMESTAMP=$timestamp
SYSTEM_ID=$sid
SYSTEM_HOST=$hostname
EOF
    
    chmod 600 "$temp_file"
    mv "$temp_file" "$hwkey_file"
    
    log_success "Hardware key generated: $hwkey_file"
    echo "$hwkey_file"
}

# Install hardware key in container
install_hwkey() {
    log_info "Installing hardware key in container..."
    
    # Check if container is running
    if ! docker ps | grep -q "$CONTAINER_NAME"; then
        log_error "Container '$CONTAINER_NAME' is not running"
        return 1
    fi
    
    local latest_hwkey=$(ls -t "$HWKEY_DIR"/hwkey_*.key 2>/dev/null | head -1)
    
    if [ -z "$latest_hwkey" ]; then
        log_warning "No hardware keys found. Generating new one..."
        latest_hwkey=$(generate_hwkey)
    fi
    
    log_info "Installing key from: $latest_hwkey"
    
    # Copy key to container
    docker cp "$latest_hwkey" "$CONTAINER_NAME":/usr/sap/npl/SYS/etc/license/hwkey 2>/dev/null || {
        log_warning "Direct copy failed, using alternative method..."
        cat "$latest_hwkey" | docker exec -i "$CONTAINER_NAME" tee /usr/sap/npl/SYS/etc/license/hwkey > /dev/null
    }
    
    # Set permissions
    docker exec "$CONTAINER_NAME" chmod 600 /usr/sap/npl/SYS/etc/license/hwkey 2>/dev/null || true
    
    log_success "Hardware key installed in container"
}

# Verify hardware key installation
verify_hwkey() {
    log_info "Verifying hardware key installation..."
    
    if ! docker ps | grep -q "$CONTAINER_NAME"; then
        log_error "Container '$CONTAINER_NAME' is not running"
        return 1
    fi
    
    # Check if hwkey exists in container
    if docker exec "$CONTAINER_NAME" test -f /usr/sap/npl/SYS/etc/license/hwkey 2>/dev/null; then
        log_success "Hardware key found in container"
        log_info "Key details:"
        docker exec "$CONTAINER_NAME" head -5 /usr/sap/npl/SYS/etc/license/hwkey 2>/dev/null || true
        return 0
    else
        log_error "Hardware key not found in container"
        return 1
    fi
}

# Show hardware key status
show_status() {
    log_info "Hardware Key Status"
    echo "====================="
    
    if [ -d "$HWKEY_DIR" ]; then
        local key_count=$(ls -1 "$HWKEY_DIR"/hwkey_*.key 2>/dev/null | wc -l)
        log_info "Generated keys: $key_count"
        
        if [ $key_count -gt 0 ]; then
            log_info "Latest hardware keys:"
            ls -lt "$HWKEY_DIR"/hwkey_*.key 2>/dev/null | head -5 | awk '{print "  " $9}'
        fi
    else
        log_warning "No hardware key directory found"
    fi
    
    if [ -f "$HWKEY_CONFIG" ]; then
        log_success "Configuration file: $HWKEY_CONFIG"
    fi
    
    if docker ps | grep -q "$CONTAINER_NAME" 2>/dev/null; then
        log_info "Container status: RUNNING"
        verify_hwkey || log_warning "Hardware key not installed in container"
    else
        log_warning "Container status: NOT RUNNING"
    fi
}

# Main logic
COMMAND="${1:-status}"

case "$COMMAND" in
    generate)
        create_hwkey_config
        generate_hwkey
        ;;
    install)
        install_hwkey
        ;;
    verify)
        verify_hwkey
        ;;
    status)
        show_status
        ;;
    setup)
        # Complete setup: generate and install
        create_hwkey_config
        generate_hwkey
        install_hwkey
        verify_hwkey
        ;;
    *)
        echo "Usage: $0 {generate|install|verify|status|setup}"
        echo ""
        echo "Commands:"
        echo "  generate - Generate a new hardware key"
        echo "  install  - Install hardware key in container"
        echo "  verify   - Verify hardware key installation"
        echo "  status   - Show hardware key status"
        echo "  setup    - Complete setup (generate + install + verify)"
        exit 1
        ;;
esac
