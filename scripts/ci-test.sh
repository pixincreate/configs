#!/usr/bin/env bash
# CI Test Script for Dotfiles Setup
# Tests the complete setup process and individual components

set -euo pipefail

# Color codes for output
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly NC='\033[0m' # No Color

# Script configuration
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly SETUP_SCRIPT="$SCRIPT_DIR/setup"
readonly BACKUP_DIR="$HOME/.dotfiles-ci-backup"
readonly LOG_FILE="/tmp/dotfiles-ci-test.log"

# Test configuration
TEST_FULL_SETUP=true
TEST_INDIVIDUAL_SETUPS=true
CLEANUP_AFTER_TEST=true
DRY_RUN_ONLY=false

# Logging functions
log_info() { echo -e "${GREEN}[INFO]${NC} $*" | tee -a "$LOG_FILE"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $*" | tee -a "$LOG_FILE"; }
log_error() { echo -e "${RED}[ERROR]${NC} $*" | tee -a "$LOG_FILE"; }
log_step() { echo -e "${BLUE}[STEP]${NC} $*" | tee -a "$LOG_FILE"; }

# Error handling
error_exit() {
    log_error "$1"
    cleanup_test_environment
    exit 1
}

# Cleanup function
cleanup_test_environment() {
    log_step "Cleaning up test environment"

    # Restore backups if they exist
    if [[ -d "$BACKUP_DIR" ]]; then
        log_info "Restoring original files from backup"

        # Restore key files
        local files_to_restore=(
            ".gitconfig"
            ".gitconfig.user"
            ".zshrc"
            ".ssh/config"
            ".config/git"
        )

        for file in "${files_to_restore[@]}"; do
            local backup_file="$BACKUP_DIR/$file"
            local target_file="$HOME/$file"

            if [[ -f "$backup_file" ]]; then
                mkdir -p "$(dirname "$target_file")"
                cp "$backup_file" "$target_file"
                log_info "Restored: $file"
            elif [[ -f "$target_file" ]]; then
                # Remove file if it didn't exist before
                rm -f "$target_file"
                log_info "Removed: $file (didn't exist before)"
            fi
        done

        # Unstow everything
        if command -v stow &> /dev/null; then
            log_info "Unstowing all packages"
            cd "$HOME/Dev/.configs" 2>/dev/null || true
            for pkg in config git ssh vscode zsh wallpaper; do
                stow --delete --dir=home --target="$HOME" "$pkg" 2>/dev/null || true
            done
        fi

        # Remove backup directory
        rm -rf "$BACKUP_DIR"
    fi

    # Remove test artifacts
    rm -rf "$HOME/.dotfiles-setup-test"
    rm -f "$HOME/.gitconfig.user"

    log_info "Test environment cleanup completed"
}

# Create backup of current state
create_backup() {
    log_step "Creating backup of current environment"

    mkdir -p "$BACKUP_DIR"

    # Backup key files
    local files_to_backup=(
        ".gitconfig"
        ".gitconfig.user"
        ".zshrc"
        ".ssh/config"
    )

    for file in "${files_to_backup[@]}"; do
        local source_file="$HOME/$file"
        local backup_file="$BACKUP_DIR/$file"

        if [[ -f "$source_file" ]]; then
            mkdir -p "$(dirname "$backup_file")"
            cp "$source_file" "$backup_file"
            log_info "Backed up: $file"
        fi
    done

    # Backup entire .config/git directory if it exists
    if [[ -d "$HOME/.config/git" ]]; then
        cp -r "$HOME/.config/git" "$BACKUP_DIR/.config/"
        log_info "Backed up: .config/git directory"
    fi
}

# Platform detection
detect_platform() {
    case "$OSTYPE" in
        darwin*)
            echo "macos"
            ;;
        linux-gnu*)
            if [[ -f /etc/fedora-release ]]; then
                echo "fedora"
            elif [[ -f /etc/debian_version ]]; then
                echo "debian"
            else
                echo "linux"
            fi
            ;;
        linux-android*)
            echo "android"
            ;;
        *)
            echo "unknown"
            ;;
    esac
}

# Check prerequisites
check_prerequisites() {
    log_step "Checking prerequisites"

    # Check if setup script exists
    if [[ ! -f "$SETUP_SCRIPT" ]]; then
        error_exit "Setup script not found at $SETUP_SCRIPT"
    fi

    # Check if Python 3 is available
    if ! command -v python3 &> /dev/null; then
        error_exit "Python 3 is required but not installed"
    fi

    # Check Python version (require 3.8+)
    local python_version
    python_version=$(python3 -c "import sys; print('.'.join(map(str, sys.version_info[:2])))")
    if ! python3 -c "import sys; sys.exit(0 if sys.version_info >= (3, 8) else 1)"; then
        error_exit "Python 3.8+ is required, found: $python_version"
    fi

    # Install requirements if needed
    if ! python3 -c "import click, rich, inquirer, yaml" &> /dev/null; then
        log_info "Installing Python requirements"
        PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
        python3 -m pip install --user -r "$PROJECT_ROOT/requirements.txt" || error_exit "Failed to install requirements"
    fi

    log_info "Prerequisites check passed"
}

# Test dry run functionality
test_dry_run() {
    log_step "Testing dry run functionality"

    # Test dry run of full setup
    if ! "$SETUP_SCRIPT" --dry-run --full-setup --force; then
        error_exit "Dry run test failed"
    fi

    log_info "Dry run test passed"
}

# Test full setup
test_full_setup() {
    if [[ "$TEST_FULL_SETUP" != "true" ]]; then
        log_info "Skipping full setup test (disabled)"
        return 0
    fi

    log_step "Testing full setup process"

    if [[ "$DRY_RUN_ONLY" == "true" ]]; then
        log_info "Running full setup in dry-run mode only"
        if ! "$SETUP_SCRIPT" --dry-run --full-setup --force; then
            error_exit "Full setup dry run failed"
        fi
    else
        log_info "Running full setup"
        if ! "$SETUP_SCRIPT" --full-setup --force; then
            error_exit "Full setup failed"
        fi

        # Verify setup results
        verify_full_setup
    fi

    log_info "Full setup test passed"
}

# Verify full setup results
verify_full_setup() {
    log_step "Verifying full setup results"

    local platform
    platform=$(detect_platform)

    # Check if .gitconfig.user was created
    if [[ ! -f "$HOME/.gitconfig.user" ]]; then
        log_warn ".gitconfig.user was not created (expected in CI)"
    fi

    # Check if directories were created
    local expected_dirs=(
        "$HOME/Pictures/Wallpapers"
        "$HOME/Pictures/Screenshots"
        "$HOME/.local/share/fonts"
    )

    for dir in "${expected_dirs[@]}"; do
        if [[ ! -d "$dir" ]]; then
            log_warn "Expected directory not created: $dir"
        else
            log_info "Directory created: $dir"
        fi
    done

    # Platform-specific checks
    case "$platform" in
        macos)
            if [[ -d "$HOME/Library/Application Support/Code" ]]; then
                log_info "macOS Code directory structure verified"
            fi
            ;;
        fedora|debian)
            if [[ -d "$HOME/.config/Code" ]]; then
                log_info "Linux Code directory structure verified"
            fi
            ;;
    esac

    log_info "Setup verification completed"
}

# Test individual setup components
test_individual_setups() {
    if [[ "$TEST_INDIVIDUAL_SETUPS" != "true" ]]; then
        log_info "Skipping individual setup tests (disabled)"
        return 0
    fi

    log_step "Testing individual setup components"

    local components=(
        "--install-packages"
        "--setup-fonts"
        "--setup-zsh"
        "--stow-configs"
        "--misc-setup"
    )

    for component in "${components[@]}"; do
        log_info "Testing component: $component"

        if [[ "$DRY_RUN_ONLY" == "true" ]]; then
            if ! "$SETUP_SCRIPT" --dry-run "$component" --force; then
                log_error "Component test failed: $component (dry run)"
                return 1
            fi
        else
            if ! "$SETUP_SCRIPT" "$component" --force; then
                log_error "Component test failed: $component"
                return 1
            fi
        fi

        log_info "Component test passed: $component"
    done

    log_info "Individual setup tests passed"
}

# Test Git setup separately (requires user input simulation)
test_git_setup() {
    log_step "Testing Git setup with dummy data"

    # Skip Git setup in CI since it requires interactive input
    # and would try to generate real SSH keys
    log_info "Skipping Git setup in CI environment (requires interactive input)"

    # Test Git setup in dry run mode
    if ! "$SETUP_SCRIPT" --dry-run --setup-git --force; then
        error_exit "Git setup dry run failed"
    fi

    log_info "Git setup dry run test passed"
}

# Performance test
test_performance() {
    log_step "Testing setup performance"

    local start_time
    start_time=$(date +%s)

    # Run a quick dry run to measure performance
    "$SETUP_SCRIPT" --dry-run --full-setup --force &> /dev/null

    local end_time
    end_time=$(date +%s)
    local duration=$((end_time - start_time))

    log_info "Setup dry run completed in ${duration} seconds"

    # Warn if it takes too long
    if [[ $duration -gt 30 ]]; then
        log_warn "Setup is taking longer than expected: ${duration}s"
    fi
}

# Main test function
run_tests() {
    log_step "Starting dotfiles setup CI tests"
    log_info "Platform: $(detect_platform)"
    log_info "Test mode: $([ "$DRY_RUN_ONLY" == "true" ] && echo "DRY RUN ONLY" || echo "FULL TEST")"

    # Initialize log file
    echo "Dotfiles Setup CI Test - $(date)" > "$LOG_FILE"

    # Run tests
    check_prerequisites
    create_backup

    # Set trap for cleanup
    trap cleanup_test_environment EXIT

    test_dry_run
    test_performance
    test_full_setup
    test_individual_setups
    test_git_setup

    log_step "All tests completed successfully!"

    # Show summary
    echo ""
    echo "========================================="
    echo "CI Test Summary"
    echo "========================================="
    echo "Platform: $(detect_platform)"
    echo "Test mode: $([ "$DRY_RUN_ONLY" == "true" ] && echo "DRY RUN ONLY" || echo "FULL TEST")"
    echo "Log file: $LOG_FILE"
    echo "Status: ✅ PASSED"
    echo "========================================="
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --dry-run-only)
            DRY_RUN_ONLY=true
            shift
            ;;
        --skip-full-setup)
            TEST_FULL_SETUP=false
            shift
            ;;
        --skip-individual)
            TEST_INDIVIDUAL_SETUPS=false
            shift
            ;;
        --no-cleanup)
            CLEANUP_AFTER_TEST=false
            shift
            ;;
        --help)
            echo "Usage: $0 [options]"
            echo "Options:"
            echo "  --dry-run-only      Only run dry-run tests"
            echo "  --skip-full-setup   Skip full setup test"
            echo "  --skip-individual   Skip individual component tests"
            echo "  --no-cleanup        Don't cleanup after tests"
            echo "  --help              Show this help"
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            exit 1
            ;;
    esac
done

# Run the tests
run_tests
