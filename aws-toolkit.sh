#!/bin/bash

# AWS CLI + Shell Scripting Toolkit
# A professional tool for automating common AWS operations
# Author: Your Name
# Version: 1.0.0

set -euo pipefail  # Exit on error, undefined vars, pipe failures

# Configuration
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly LOG_FILE="${SCRIPT_DIR}/logs/aws-toolkit.log"
readonly CONFIG_FILE="${SCRIPT_DIR}/config/settings.conf"

# Colors for output
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly PURPLE='\033[0;35m'
readonly CYAN='\033[0;36m'
readonly NC='\033[0m' # No Color

# Ensure log directory exists
mkdir -p "$(dirname "$LOG_FILE")"
mkdir -p "$(dirname "$CONFIG_FILE")"

# Logging function
log() {
    local level="$1"
    shift
    local message="$*"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo "[$timestamp] [$level] $message" >> "$LOG_FILE"
}

# Print functions
print_success() {
    echo -e "${GREEN}✓ $1${NC}"
    log "SUCCESS" "$1"
}

print_error() {
    echo -e "${RED}✗ $1${NC}" >&2
    log "ERROR" "$1"
}

print_warning() {
    echo -e "${YELLOW}⚠ $1${NC}"
    log "WARNING" "$1"
}

print_info() {
    echo -e "${BLUE}ℹ $1${NC}"
    log "INFO" "$1"
}

print_header() {
    echo -e "${PURPLE}$1${NC}"
}

# Check if AWS CLI is installed and configured
check_aws_prerequisites() {
    print_info "Checking AWS CLI prerequisites..."
    
    if ! command -v aws &> /dev/null; then
        print_error "AWS CLI is not installed. Please run ./install.sh first."
        exit 1
    fi
    
    if ! aws sts get-caller-identity &> /dev/null; then
        print_error "AWS CLI is not configured or credentials are invalid."
        print_info "Please run 'aws configure' to set up your credentials."
        exit 1
    fi
    
    print_success "AWS CLI is properly configured"
}

# Display banner
show_banner() {
    clear
    echo -e "${CYAN}"
    cat << "EOF"
    ╔══════════════════════════════════════════════════════════════╗
    ║                    AWS CLI Toolkit v1.0.0                   ║
    ║              Professional AWS Automation Tool                ║
    ╚══════════════════════════════════════════════════════════════╝
EOF
    echo -e "${NC}"
    
    # Show current AWS identity
    local aws_identity=$(aws sts get-caller-identity --query 'Account' --output text 2>/dev/null || echo "Unknown")
    local aws_region=$(aws configure get region 2>/dev/null || echo "Not set")
    
    echo -e "${BLUE}AWS Account: ${YELLOW}$aws_identity${NC}"
    echo -e "${BLUE}AWS Region:  ${YELLOW}$aws_region${NC}"
    echo ""
}

# Main menu
show_menu() {
    print_header "═══════════════════════════════════════"
    print_header "           MAIN MENU OPTIONS           "
    print_header "═══════════════════════════════════════"
    echo ""
    echo -e "${CYAN}S3 Operations:${NC}"
    echo "  1) List all S3 buckets"
    echo "  2) Upload file to S3 bucket"
    echo "  3) Download file from S3 bucket"
    echo ""
    echo -e "${CYAN}EC2 Operations:${NC}"
    echo "  4) View EC2 instances"
    echo "  5) Start/Stop EC2 instance"
    echo ""
    echo -e "${CYAN}System:${NC}"
    echo "  6) View logs"
    echo "  7) Exit"
    echo ""
    echo -n "Please select an option (1-7): "
}

# S3 Operations
list_s3_buckets() {
    print_header "📦 Listing S3 Buckets"
    echo ""
    
    if ! aws s3 ls 2>/dev/null; then
        print_error "Failed to list S3 buckets. Check your permissions."
        return 1
    fi
    
    print_success "S3 buckets listed successfully"
}

upload_to_s3() {
    print_header "📤 Upload File to S3"
    echo ""
    
    # Get file path
    read -p "Enter the full path to the file you want to upload: " file_path
    
    if [[ ! -f "$file_path" ]]; then
        print_error "File does not exist: $file_path"
        return 1
    fi
    
    # List available buckets
    print_info "Available S3 buckets:"
    aws s3 ls | awk '{print "  - " $3}'
    echo ""
    
    # Get bucket name
    read -p "Enter the S3 bucket name: " bucket_name
    
    # Validate bucket exists
    if ! aws s3 ls "s3://$bucket_name" &>/dev/null; then
        print_error "Bucket '$bucket_name' does not exist or you don't have access."
        return 1
    fi
    
    # Get optional S3 key (path)
    read -p "Enter S3 key/path (press Enter for filename only): " s3_key
    
    if [[ -z "$s3_key" ]]; then
        s3_key=$(basename "$file_path")
    fi
    
    # Upload file
    print_info "Uploading $file_path to s3://$bucket_name/$s3_key..."
    
    if aws s3 cp "$file_path" "s3://$bucket_name/$s3_key"; then
        print_success "File uploaded successfully to s3://$bucket_name/$s3_key"
    else
        print_error "Failed to upload file"
        return 1
    fi
}

download_from_s3() {
    print_header "📥 Download File from S3"
    echo ""
    
    # List available buckets
    print_info "Available S3 buckets:"
    aws s3 ls | awk '{print "  - " $3}'
    echo ""
    
    # Get bucket name
    read -p "Enter the S3 bucket name: " bucket_name
    
    # Validate bucket exists
    if ! aws s3 ls "s3://$bucket_name" &>/dev/null; then
        print_error "Bucket '$bucket_name' does not exist or you don't have access."
        return 1
    fi
    
    # Show bucket contents
    print_info "Contents of bucket '$bucket_name':"
    aws s3 ls "s3://$bucket_name" --recursive | head -20
    echo ""
    
    # Get S3 key
    read -p "Enter the S3 key/path of the file to download: " s3_key
    
    # Get local destination
    read -p "Enter local destination path (press Enter for current directory): " local_path
    
    if [[ -z "$local_path" ]]; then
        local_path="./$(basename "$s3_key")"
    fi
    
    # Download file
    print_info "Downloading s3://$bucket_name/$s3_key to $local_path..."
    
    if aws s3 cp "s3://$bucket_name/$s3_key" "$local_path"; then
        print_success "File downloaded successfully to $local_path"
    else
        print_error "Failed to download file"
        return 1
    fi
}

# EC2 Operations
view_ec2_instances() {
    print_header "🖥️  EC2 Instances Overview"
    echo ""
    
    # Get instances with formatted output
    local instances=$(aws ec2 describe-instances \
        --query 'Reservations[*].Instances[*].[InstanceId,State.Name,InstanceType,Tags[?Key==`Name`].Value|[0]]' \
        --output table 2>/dev/null)
    
    if [[ -z "$instances" ]]; then
        print_warning "No EC2 instances found in the current region."
        return 0
    fi
    
    echo "$instances"
    print_success "EC2 instances retrieved successfully"
}

start_stop_ec2() {
    print_header "⚡ Start/Stop EC2 Instance"
    echo ""
    
    # Show current instances
    print_info "Current EC2 instances:"
    aws ec2 describe-instances \
        --query 'Reservations[*].Instances[*].[InstanceId,State.Name,Tags[?Key==`Name`].Value|[0]]' \
        --output table
    echo ""
    
    # Get instance ID
    read -p "Enter the EC2 Instance ID: " instance_id
    
    # Validate instance exists
    if ! aws ec2 describe-instances --instance-ids "$instance_id" &>/dev/null; then
        print_error "Instance '$instance_id' not found or you don't have access."
        return 1
    fi
    
    # Get current state
    local current_state=$(aws ec2 describe-instances \
        --instance-ids "$instance_id" \
        --query 'Reservations[0].Instances[0].State.Name' \
        --output text)
    
    print_info "Current state of $instance_id: $current_state"
    
    # Action menu
    echo ""
    echo "Available actions:"
    echo "  1) Start instance"
    echo "  2) Stop instance"
    echo "  3) Reboot instance"
    echo ""
    read -p "Select action (1-3): " action
    
    case $action in
        1)
            if [[ "$current_state" == "running" ]]; then
                print_warning "Instance is already running."
                return 0
            fi
            print_info "Starting instance $instance_id..."
            if aws ec2 start-instances --instance-ids "$instance_id" &>/dev/null; then
                print_success "Instance start command sent successfully"
            else
                print_error "Failed to start instance"
                return 1
            fi
            ;;
        2)
            if [[ "$current_state" == "stopped" ]]; then
                print_warning "Instance is already stopped."
                return 0
            fi
            print_info "Stopping instance $instance_id..."
            if aws ec2 stop-instances --instance-ids "$instance_id" &>/dev/null; then
                print_success "Instance stop command sent successfully"
            else
                print_error "Failed to stop instance"
                return 1
            fi
            ;;
        3)
            print_info "Rebooting instance $instance_id..."
            if aws ec2 reboot-instances --instance-ids "$instance_id" &>/dev/null; then
                print_success "Instance reboot command sent successfully"
            else
                print_error "Failed to reboot instance"
                return 1
            fi
            ;;
        *)
            print_error "Invalid selection"
            return 1
            ;;
    esac
}

# View logs
view_logs() {
    print_header "📋 Recent Log Entries"
    echo ""
    
    if [[ -f "$LOG_FILE" ]]; then
        tail -20 "$LOG_FILE"
    else
        print_warning "No log file found."
    fi
    
    echo ""
    read -p "Press Enter to continue..."
}

# Main execution loop
main() {
    # Check prerequisites
    check_aws_prerequisites
    
    # Main loop
    while true; do
        show_banner
        show_menu
        
        read -r choice
        echo ""
        
        case $choice in
            1)
                list_s3_buckets
                ;;
            2)
                upload_to_s3
                ;;
            3)
                download_from_s3
                ;;
            4)
                view_ec2_instances
                ;;
            5)
                start_stop_ec2
                ;;
            6)
                view_logs
                ;;
            7)
                print_success "Thank you for using AWS CLI Toolkit!"
                exit 0
                ;;
            *)
                print_error "Invalid option. Please select 1-7."
                ;;
        esac
        
        echo ""
        read -p "Press Enter to continue..."
    done
}

# Trap to handle script interruption
trap 'print_warning "Script interrupted by user"; exit 130' INT

# Run main function
main "$@"
