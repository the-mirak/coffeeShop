#!/bin/bash

# CoffeeShop Application Cleanup Script
# This script safely removes the CloudFormation stack and associated resources

set -e

# Default values
STACK_NAME="coffeeshop-prod"
REGION="us-east-1"
FORCE_DELETE=false

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Function to check if AWS CLI is installed
check_aws_cli() {
    if ! command -v aws &> /dev/null; then
        print_error "AWS CLI is not installed. Please install it first."
        exit 1
    fi
    
    # Check if AWS credentials are configured
    if ! aws sts get-caller-identity &> /dev/null; then
        print_error "AWS credentials not configured. Please run 'aws configure' first."
        exit 1
    fi
    
    print_success "AWS CLI is configured and ready"
}

# Function to check if stack exists
check_stack_exists() {
    if ! aws cloudformation describe-stacks --stack-name "$STACK_NAME" --region "$REGION" &> /dev/null; then
        print_error "Stack '$STACK_NAME' not found in region '$REGION'"
        print_status "Available stacks:"
        aws cloudformation list-stacks --region "$REGION" --stack-status-filter CREATE_COMPLETE UPDATE_COMPLETE --query 'StackSummaries[].StackName' --output table
        exit 1
    fi
    print_success "Stack '$STACK_NAME' found"
}

# Function to get S3 bucket name from stack
get_s3_bucket() {
    S3_BUCKET=$(aws cloudformation describe-stacks \
        --stack-name "$STACK_NAME" \
        --region "$REGION" \
        --query 'Stacks[0].Outputs[?OutputKey==`S3BucketName`].OutputValue' \
        --output text 2>/dev/null || echo "")
    
    if [ -n "$S3_BUCKET" ] && [ "$S3_BUCKET" != "None" ]; then
        print_status "Found S3 bucket: $S3_BUCKET"
    else
        print_warning "Could not determine S3 bucket name from stack outputs"
        S3_BUCKET=""
    fi
}

# Function to empty S3 bucket
empty_s3_bucket() {
    if [ -z "$S3_BUCKET" ]; then
        print_warning "No S3 bucket to clean up"
        return
    fi
    
    print_status "Checking S3 bucket contents..."
    
    # Check if bucket exists and has objects
    local object_count
    object_count=$(aws s3api list-objects-v2 --bucket "$S3_BUCKET" --query 'length(Contents)' --output text 2>/dev/null || echo "0")
    
    if [ "$object_count" = "None" ] || [ "$object_count" = "0" ]; then
        print_status "S3 bucket is already empty"
        return
    fi
    
    print_warning "S3 bucket contains $object_count objects"
    
    if [ "$FORCE_DELETE" = false ]; then
        echo
        print_warning "The S3 bucket '$S3_BUCKET' contains objects that need to be deleted before the stack can be removed."
        print_status "Objects in bucket:"
        aws s3 ls s3://"$S3_BUCKET" --recursive
        echo
        read -p "Do you want to delete all objects in the S3 bucket? (y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            print_error "Cannot proceed without emptying the S3 bucket"
            print_status "Please manually empty the bucket or use --force flag"
            exit 1
        fi
    fi
    
    print_status "Emptying S3 bucket..."
    aws s3 rm s3://"$S3_BUCKET" --recursive
    
    if [ $? -eq 0 ]; then
        print_success "S3 bucket emptied successfully"
    else
        print_error "Failed to empty S3 bucket"
        exit 1
    fi
}

# Function to delete CloudFormation stack
delete_stack() {
    print_status "Deleting CloudFormation stack '$STACK_NAME'..."
    
    aws cloudformation delete-stack \
        --stack-name "$STACK_NAME" \
        --region "$REGION"
    
    if [ $? -eq 0 ]; then
        print_success "Stack deletion initiated"
    else
        print_error "Failed to initiate stack deletion"
        exit 1
    fi
}

# Function to wait for stack deletion
wait_for_deletion() {
    print_status "Waiting for stack deletion to complete..."
    print_warning "This may take several minutes..."
    
    aws cloudformation wait stack-delete-complete \
        --stack-name "$STACK_NAME" \
        --region "$REGION"
    
    if [ $? -eq 0 ]; then
        print_success "Stack deleted successfully!"
    else
        print_error "Stack deletion failed or timed out"
        print_status "Check the CloudFormation console for details"
        
        # Show current stack status
        local stack_status
        stack_status=$(aws cloudformation describe-stacks \
            --stack-name "$STACK_NAME" \
            --region "$REGION" \
            --query 'Stacks[0].StackStatus' \
            --output text 2>/dev/null || echo "STACK_NOT_FOUND")
        
        if [ "$stack_status" != "STACK_NOT_FOUND" ]; then
            print_status "Current stack status: $stack_status"
            
            # Show recent stack events
            print_status "Recent stack events:"
            aws cloudformation describe-stack-events \
                --stack-name "$STACK_NAME" \
                --region "$REGION" \
                --query 'StackEvents[0:5].[Timestamp,ResourceStatus,ResourceType,LogicalResourceId,ResourceStatusReason]' \
                --output table
        fi
        
        exit 1
    fi
}

# Function to verify cleanup
verify_cleanup() {
    print_status "Verifying cleanup..."
    
    # Check if stack still exists
    if aws cloudformation describe-stacks --stack-name "$STACK_NAME" --region "$REGION" &> /dev/null; then
        print_warning "Stack still exists - deletion may not be complete"
        return 1
    fi
    
    # Check if S3 bucket still exists (it should be deleted by CloudFormation)
    if [ -n "$S3_BUCKET" ]; then
        if aws s3api head-bucket --bucket "$S3_BUCKET" &> /dev/null; then
            print_warning "S3 bucket '$S3_BUCKET' still exists"
            print_status "This may be normal if the bucket was created outside of CloudFormation"
        else
            print_success "S3 bucket has been deleted"
        fi
    fi
    
    print_success "Cleanup verification completed"
}

# Function to show usage
show_usage() {
    echo "Usage: $0 [OPTIONS]"
    echo
    echo "Options:"
    echo "  -s, --stack-name NAME    CloudFormation stack name (default: $STACK_NAME)"
    echo "  -r, --region REGION      AWS region (default: $REGION)"
    echo "  -f, --force              Force deletion without prompts"
    echo "  -h, --help               Show this help message"
    echo
    echo "Example:"
    echo "  $0 --stack-name my-coffeeshop --region us-west-2"
    echo "  $0 --force  # Delete without confirmation prompts"
    echo
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -s|--stack-name)
            STACK_NAME="$2"
            shift 2
            ;;
        -r|--region)
            REGION="$2"
            shift 2
            ;;
        -f|--force)
            FORCE_DELETE=true
            shift
            ;;
        -h|--help)
            show_usage
            exit 0
            ;;
        *)
            print_error "Unknown option: $1"
            show_usage
            exit 1
            ;;
    esac
done

# Main execution
main() {
    echo "========================================"
    echo "CoffeeShop Application Cleanup Script"
    echo "========================================"
    echo
    
    print_status "Configuration:"
    echo "  Stack Name: $STACK_NAME"
    echo "  Region: $REGION"
    echo "  Force Delete: $FORCE_DELETE"
    echo
    
    if [ "$FORCE_DELETE" = false ]; then
        print_warning "This will permanently delete the CloudFormation stack and all associated resources!"
        print_warning "This action cannot be undone."
        echo
        read -p "Are you sure you want to proceed? (y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            print_status "Cleanup cancelled"
            exit 0
        fi
        echo
    fi
    
    # Pre-cleanup checks
    check_aws_cli
    check_stack_exists
    get_s3_bucket
    
    # Cleanup process
    empty_s3_bucket
    delete_stack
    wait_for_deletion
    verify_cleanup
    
    echo
    echo "========================================"
    print_success "Cleanup completed successfully!"
    print_status "All CoffeeShop application resources have been removed."
    echo "========================================"
}

# Run main function
main