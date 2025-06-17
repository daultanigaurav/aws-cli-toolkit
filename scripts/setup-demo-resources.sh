#!/bin/bash

# Demo Resource Setup Script
# Creates sample AWS resources for testing the toolkit

set -euo pipefail

# Colors
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly NC='\033[0m'

print_info() {
    echo -e "${BLUE}ℹ $1${NC}"
}

print_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠ $1${NC}"
}

# Create demo S3 bucket
create_demo_bucket() {
    local bucket_name="aws-toolkit-demo-$(date +%s)"
    local region=$(aws configure get region)
    
    print_info "Creating demo S3 bucket: $bucket_name"
    
    if [[ "$region" == "us-east-1" ]]; then
        aws s3 mb "s3://$bucket_name"
    else
        aws s3 mb "s3://$bucket_name" --region "$region"
    fi
    
    # Create a sample file
    echo "This is a demo file created by AWS CLI Toolkit" > demo-file.txt
    echo "Timestamp: $(date)" >> demo-file.txt
    echo "Region: $region" >> demo-file.txt
    
    # Upload sample file
    aws s3 cp demo-file.txt "s3://$bucket_name/demo-file.txt"
    
    # Clean up local file
    rm demo-file.txt
    
    print_success "Demo S3 bucket created: $bucket_name"
    echo "  - Contains: demo-file.txt"
    echo "  - You can test download functionality with this file"
}

# Display current resources
show_current_resources() {
    print_info "Current AWS resources in your account:"
    echo ""
    
    print_info "S3 Buckets:"
    aws s3 ls | head -10
    echo ""
    
    print_info "EC2 Instances:"
    aws ec2 describe-instances \
        --query 'Reservations[*].Instances[*].[InstanceId,State.Name,InstanceType]' \
        --output table | head -15
}

main() {
    echo "AWS CLI Toolkit - Demo Resource Setup"
    echo "====================================="
    echo ""
    
    print_warning "This script will create demo AWS resources that may incur charges."
    read -p "Do you want to continue? (y/N): " -n 1 -r
    echo ""
    
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        print_info "Setup cancelled."
        exit 0
    fi
    
    echo ""
    create_demo_bucket
    echo ""
    show_current_resources
    echo ""
    print_success "Demo setup completed!"
    print_info "You can now test the AWS CLI Toolkit with these resources."
}

main "$@"
