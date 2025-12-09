#!/bin/bash

# SAP ABAP 7.52 SP04 Docker Environment Installer
# Automates the setup and startup of the SAP ABAP developer environment
# Usage: ./scripts/install-abap.sh [start|stop|restart|status]

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

echo "SAP ABAP Developer Boxes Installer"
echo "==================================="

# Color output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Helper functions
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

# Check Docker installation
check_docker() {
    log_info "Checking Docker installation..."
    if ! command -v docker &> /dev/null; then
        log_error "Docker is not installed. Please install Docker 20.10+ and try again."
        exit 1
    fi
    
    if ! command -v docker-compose &> /dev/null; then
        log_error "Docker Compose is not installed. Please install Docker Compose 2.0+ and try again."
        exit 1
    fi
    
    log_success "Docker and Docker Compose are installed"
}

# Start services
start_services() {
    log_info "Starting SAP ABAP development environment..."
    cd "$PROJECT_DIR"
    docker-compose up -d
    log_success "SAP ABAP environment started successfully"
    log_info "Waiting for services to be ready (this may take 2-3 minutes)..."
    sleep 5
}

# Stop services
stop_services() {
    log_info "Stopping SAP ABAP development environment..."
    cd "$PROJECT_DIR"
    docker-compose down
    log_success "SAP ABAP environment stopped"
}

# Show service status
show_status() {
    log_info "SAP ABAP environment status:"
    cd "$PROJECT_DIR"
    docker-compose ps
}

# Main logic
COMMAND="${1:-start}"

case "$COMMAND" in
    start)
        check_docker
        start_services
        echo ""
        log_info "Access SAP system:"
        echo "  URL: http://localhost:8000"
        echo "  User: DEVELOPER"
        echo "  Password: See docker-compose.yml"
        ;;
    stop)
        stop_services
        ;;
    restart)
        stop_services
        sleep 2
        start_services
        ;;
    status)
        show_status
        ;;
    *)
        echo "Usage: $0 {start|stop|restart|status}"
        echo ""
        echo "Commands:"
        echo "  start   - Start the SAP ABAP development environment"
        echo "  stop    - Stop the SAP ABAP development environment"
        echo "  restart - Restart the SAP ABAP development environment"
        echo "  status  - Show the status of the development environment"
        exit 1
        ;;
esac
