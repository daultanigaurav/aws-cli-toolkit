#!/bin/bash

# Demo Resource Cleanup Script
# Removes demo resources created by setup-demo-resources.sh

set -euo pipefail

# Colors
readonly RED='\033[0;31m'
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

print_error() {
    echo -e "${RED}✗ $1${NC}"
}

# Clean up demo S3 buckets
cleanup_demo_buckets() {
    print_info "Looking for demo S3 buckets..."
    
    local demo_buckets=$(aws s3 ls | grep "aws-toolkit-demo-" | awk '{print $3}' || true)
    
    if [[ -z "$demo_buckets" ]]; then
        print_info "No demo S3 buckets found."
        return 0
    fi
    
    echo "Found demo buckets:"
    echo "$demo_buckets"
    echo ""
    
    read -p "Delete these buckets and all their contents? (y/N): " -n 1 -r
    echo ""
    
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        while IFS= read -r bucket; do
            if [[ -n "$bucket" ]]; then
                print_info "Deleting bucket: $bucket"
                aws s3 rb "s3://$bucket" --force
                print_success "Deleted: $bucket"
            fi
        done <<< "$demo_buckets"
    else
        print_info "Bucket cleanup cancelled."
    fi
}

# Show remaining resources
show_remaining_resources() {
    print_info "Remaining AWS resources:"
    echo ""
    
    print_info "S3 Buckets:"
    aws s3 ls | head -10
    echo ""
}

main() {
    echo "AWS CLI Toolkit - Demo Resource Cleanup"
    echo "======================================="
    echo ""
    
    print_warning "This script will delete demo AWS resources."
    print_warning "Make sure you don't have important data in demo buckets!"
    echo ""
    
    cleanup_demo_buckets
    echo ""
    show_remaining_resources
    echo ""
    print_success "Cleanup completed!"
}

main "$@"
