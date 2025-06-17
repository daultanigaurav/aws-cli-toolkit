#!/bin/bash

# AWS CLI Toolkit Installation Script
# Checks and installs prerequisites for the AWS CLI Toolkit

set -euo pipefail

# Colors
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly NC='\033[0m'

print_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

print_error() {
    echo -e "${RED}✗ $1${NC}" >&2
}

print_warning() {
    echo -e "${YELLOW}⚠ $1${NC}"
}

print_info() {
    echo -e "${BLUE}ℹ $1${NC}"
}

print_header() {
    echo -e "${BLUE}$1${NC}"
}

show_banner() {
    clear
    echo -e "${BLUE}"
    cat << "EOF"
    ╔══════════════════════════════════════════════════════════════╗
    ║              AWS CLI Toolkit - Installation                  ║
    ║                  Prerequisites Checker                       ║
    ╚══════════════════════════════════════════════════════════════╝
EOF
    echo -e "${NC}"
}

# Check if running on supported OS
check_os() {
    print_info "Checking operating system..."
    
    case "$(uname -s)" in
        Linux*)     
            OS="Linux"
            print_success "Running on Linux"
            ;;
        Darwin*)    
            OS="Mac"
            print_success "Running on macOS"
            ;;
        CYGWIN*|MINGW*|MSYS*)
            OS="Windows"
            print_success "Running on Windows (Git Bash/WSL)"
            ;;
        *)
            print_error "Unsupported operating system: $(uname -s)"
            exit 1
            ;;
    esac
}

# Check Bash version
check_bash() {
    print_info "Checking Bash version..."
    
    if [[ -z "${BASH_VERSION:-}" ]]; then
        print_error "This script requires Bash"
        exit 1
    fi
    
    local bash_major_version="${BASH_VERSION%%.*}"
    if [[ "$bash_major_version" -lt 4 ]]; then
        print_warning "Bash version $BASH_VERSION detected. Version 4+ recommended."
    else
        print_success "Bash version $BASH_VERSION is compatible"
    fi
}

# Check if AWS CLI is installed
check_aws_cli() {
    print_info "Checking AWS CLI installation..."
    
    if command -v aws &> /dev/null; then
        local aws_version=$(aws --version 2>&1 | cut -d/ -f2 | cut -d' ' -f1)
        print_success "AWS CLI version $aws_version is installed"
        return 0
    else
        print_warning "AWS CLI is not installed"
        return 1
    fi
}

# Install AWS CLI
install_aws_cli() {
    print_info "Installing AWS CLI..."
    
    case "$OS" in
        "Linux")
            if command -v curl &> /dev/null; then
                curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
                if command -v unzip &> /dev/null; then
                    unzip awscliv2.zip
                    sudo ./aws/install
                    rm -rf awscliv2.zip aws/
                    print_success "AWS CLI installed successfully"
                else
                    print_error "unzip is required but not installed. Please install unzip and try again."
                    exit 1
                fi
            else
                print_error "curl is required but not installed. Please install curl and try again."
                exit 1
            fi
            ;;
        "Mac")
            if command -v brew &> /dev/null; then
                brew install awscli
                print_success "AWS CLI installed via Homebrew"
            else
                print_info "Homebrew not found. Installing AWS CLI manually..."
                curl "https://awscli.amazonaws.com/AWSCLIV2.pkg" -o "AWSCLIV2.pkg"
                sudo installer -pkg AWSCLIV2.pkg -target /
                rm AWSCLIV2.pkg
                print_success "AWS CLI installed successfully"
            fi
            ;;
        "Windows")
            print_warning "Please install AWS CLI manually from: https://aws.amazon.com/cli/"
            print_info "Or use: winget install Amazon.AWSCLI"
            ;;
    esac
}

# Check AWS CLI configuration
check_aws_config() {
    print_info "Checking AWS CLI configuration..."
    
    if aws sts get-caller-identity &> /dev/null; then
        local account_id=$(aws sts get-caller-identity --query Account --output text)
        local user_arn=$(aws sts get-caller-identity --query Arn --output text)
        print_success "AWS CLI is configured"
        print_info "Account ID: $account_id"
        print_info "User/Role: $user_arn"
        return 0
    else
        print_warning "AWS CLI is not configured"
        return 1
    fi
}

# Configure AWS CLI
configure_aws_cli() {
    print_info "Starting AWS CLI configuration..."
    print_warning "You'll need your AWS Access Key ID and Secret Access Key"
    print_info "You can find these in the AWS Console under IAM > Users > Security Credentials"
    echo ""
    
    aws configure
    
    if check_aws_config; then
        print_success "AWS CLI configured successfully"
    else
        print_error "AWS CLI configuration failed"
        exit 1
    fi
}

# Check required tools
check_required_tools() {
    print_info "Checking required tools..."
    
    local missing_tools=()
    
    # Check for required commands
    local required_commands=("curl" "grep" "awk" "sed" "cut" "head" "tail")
    
    for cmd in "${required_commands[@]}"; do
        if ! command -v "$cmd" &> /dev/null; then
            missing_tools+=("$cmd")
        fi
    done
    
    if [[ ${#missing_tools[@]} -eq 0 ]]; then
        print_success "All required tools are available"
    else
        print_error "Missing required tools: ${missing_tools[*]}"
        print_info "Please install these tools and run the installer again"
        exit 1
    fi
}

# Create directory structure
create_directories() {
    print_info "Creating directory structure..."
    
    local dirs=("logs" "config" "temp")
    
    for dir in "${dirs[@]}"; do
        if [[ ! -d "$dir" ]]; then
            mkdir -p "$dir"
            print_success "Created directory: $dir"
        fi
    done
}

# Set permissions
set_permissions() {
    print_info "Setting file permissions..."
    
    if [[ -f "aws-toolkit.sh" ]]; then
        chmod +x aws-toolkit.sh
        print_success "Made aws-toolkit.sh executable"
    fi
    
    if [[ -f "install.sh" ]]; then
        chmod +x install.sh
        print_success "Made install.sh executable"
    fi
}

# Main installation process
main() {
    show_banner
    
    print_header "Starting AWS CLI Toolkit installation..."
    echo ""
    
    # Run checks
    check_os
    check_bash
    check_required_tools
    
    # Check and install AWS CLI
    if ! check_aws_cli; then
        read -p "Would you like to install AWS CLI? (y/N): " -n 1 -r
        echo ""
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            install_aws_cli
        else
            print_error "AWS CLI is required. Please install it manually and run this script again."
            exit 1
        fi
    fi
    
    # Check and configure AWS CLI
    if ! check_aws_config; then
        read -p "Would you like to configure AWS CLI now? (y/N): " -n 1 -r
        echo ""
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            configure_aws_cli
        else
            print_warning "AWS CLI needs to be configured before using the toolkit."
            print_info "Run 'aws configure' manually when ready."
        fi
    fi
    
    # Create directories and set permissions
    create_directories
    set_permissions
    
    echo ""
    print_success "Installation completed successfully!"
    echo ""
    print_info "You can now run the AWS CLI Toolkit with: ./aws-toolkit.sh"
    print_info "Or make it globally available by adding it to your PATH"
    echo ""
}

# Run main function
main "$@"
