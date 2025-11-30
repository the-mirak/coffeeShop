#!/bin/bash

# CoffeeShop Application Deployment Script
# This script deploys the CloudFormation template for the CoffeeShop FastAPI application

set -e

# Default values
STACK_NAME="coffeeshop-prod"
REGION="us-east-1"
INSTANCE_TYPE="t3.micro"
MIN_SIZE=1
MAX_SIZE=3
DESIRED_CAPACITY=2
ENVIRONMENT_NAME="CoffeeShop"

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

# Function to validate key pair exists
validate_key_pair() {
    local key_name=$1
    if ! aws ec2 describe-key-pairs --key-names "$key_name" --region "$REGION" &> /dev/null; then
        print_error "Key pair '$key_name' not found in region '$REGION'"
        print_status "Available key pairs:"
        aws ec2 describe-key-pairs --region "$REGION" --query 'KeyPairs[].KeyName' --output table
        exit 1
    fi
    print_success "Key pair '$key_name' validated"
}

# Function to check if CloudFormation template exists
check_template() {
    if [ ! -f "cloudformation-template.yaml" ]; then
        print_error "CloudFormation template 'cloudformation-template.yaml' not found in current directory"
        exit 1
    fi
    print_success "CloudFormation template found"
}

# Function to validate template
validate_template() {
    print_status "Validating CloudFormation template..."
    if aws cloudformation validate-template --template-body file://cloudformation-template.yaml --region "$REGION" &> /dev/null; then
        print_success "Template validation passed"
    else
        print_error "Template validation failed"
        aws cloudformation validate-template --template-body file://cloudformation-template.yaml --region "$REGION"
        exit 1
    fi
}

# Function to check if stack already exists
check_existing_stack() {
    if aws cloudformation describe-stacks --stack-name "$STACK_NAME" --region "$REGION" &> /dev/null; then
        print_warning "Stack '$STACK_NAME' already exists"
        read -p "Do you want to update the existing stack? (y/N): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            UPDATE_STACK=true
        else
            print_status "Deployment cancelled"
            exit 0
        fi
    else
        UPDATE_STACK=false
    fi
}

# Function to deploy stack
deploy_stack() {
    local action
    if [ "$UPDATE_STACK" = true ]; then
        action="update-stack"
        print_status "Updating CloudFormation stack '$STACK_NAME'..."
    else
        action="create-stack"
        print_status "Creating CloudFormation stack '$STACK_NAME'..."
    fi
    
    aws cloudformation $action \
        --stack-name "$STACK_NAME" \
        --template-body file://cloudformation-template.yaml \
        --parameters \
            ParameterKey=EnvironmentName,ParameterValue="$ENVIRONMENT_NAME" \
            ParameterKey=InstanceType,ParameterValue="$INSTANCE_TYPE" \
            ParameterKey=KeyName,ParameterValue="$KEY_NAME" \
            ParameterKey=MinSize,ParameterValue="$MIN_SIZE" \
            ParameterKey=MaxSize,ParameterValue="$MAX_SIZE" \
            ParameterKey=DesiredCapacity,ParameterValue="$DESIRED_CAPACITY" \
        --capabilities CAPABILITY_NAMED_IAM \
        --region "$REGION" \
        --tags \
            Key=Project,Value=CoffeeShop \
            Key=Environment,Value=Production \
            Key=ManagedBy,Value=CloudFormation
    
    if [ $? -eq 0 ]; then
        print_success "Stack deployment initiated successfully"
    else
        print_error "Stack deployment failed"
        exit 1
    fi
}

# Function to wait for stack completion
wait_for_stack() {
    local status
    if [ "$UPDATE_STACK" = true ]; then
        status="UPDATE_COMPLETE"
        print_status "Waiting for stack update to complete..."
    else
        status="CREATE_COMPLETE"
        print_status "Waiting for stack creation to complete..."
    fi
    
    if [ "$UPDATE_STACK" = true ]; then
        aws cloudformation wait stack-update-complete \
            --stack-name "$STACK_NAME" \
            --region "$REGION"
    else
        aws cloudformation wait stack-create-complete \
            --stack-name "$STACK_NAME" \
            --region "$REGION"
    fi
    
    if [ $? -eq 0 ]; then
        print_success "Stack deployment completed successfully!"
    else
        print_error "Stack deployment failed or timed out"
        print_status "Check the CloudFormation console for details"
        exit 1
    fi
}

# Function to display stack outputs
show_outputs() {
    print_status "Stack outputs:"
    aws cloudformation describe-stacks \
        --stack-name "$STACK_NAME" \
        --region "$REGION" \
        --query 'Stacks[0].Outputs[*].[OutputKey,OutputValue,Description]' \
        --output table
    
    # Get the load balancer URL specifically
    local lb_url
    lb_url=$(aws cloudformation describe-stacks \
        --stack-name "$STACK_NAME" \
        --region "$REGION" \
        --query 'Stacks[0].Outputs[?OutputKey==`LoadBalancerUrl`].OutputValue' \
        --output text)
    
    if [ -n "$lb_url" ]; then
        echo
        print_success "Application URL: $lb_url"
        print_status "Health check: $lb_url/healthz"
        print_status "Admin panel: $lb_url/admin"
    fi
}

# Function to show usage
show_usage() {
    echo "Usage: $0 [OPTIONS]"
    echo
    echo "Options:"
    echo "  -s, --stack-name NAME       CloudFormation stack name (default: $STACK_NAME)"
    echo "  -r, --region REGION         AWS region (default: $REGION)"
    echo "  -k, --key-name KEY          EC2 key pair name (required)"
    echo "  -t, --instance-type TYPE    EC2 instance type (default: $INSTANCE_TYPE)"
    echo "  -e, --environment NAME      Environment name prefix (default: $ENVIRONMENT_NAME)"
    echo "  --min-size NUMBER           Minimum instances (default: $MIN_SIZE)"
    echo "  --max-size NUMBER           Maximum instances (default: $MAX_SIZE)"
    echo "  --desired-capacity NUMBER   Desired instances (default: $DESIRED_CAPACITY)"
    echo "  -h, --help                  Show this help message"
    echo
    echo "Example:"
    echo "  $0 --key-name my-key-pair --instance-type t3.small"
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
        -k|--key-name)
            KEY_NAME="$2"
            shift 2
            ;;
        -t|--instance-type)
            INSTANCE_TYPE="$2"
            shift 2
            ;;
        -e|--environment)
            ENVIRONMENT_NAME="$2"
            shift 2
            ;;
        --min-size)
            MIN_SIZE="$2"
            shift 2
            ;;
        --max-size)
            MAX_SIZE="$2"
            shift 2
            ;;
        --desired-capacity)
            DESIRED_CAPACITY="$2"
            shift 2
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

# Validate required parameters
if [ -z "$KEY_NAME" ]; then
    print_error "Key pair name is required. Use -k or --key-name option."
    show_usage
    exit 1
fi

# Main execution
main() {
    echo "=========================================="
    echo "CoffeeShop Application Deployment Script"
    echo "=========================================="
    echo
    
    print_status "Configuration:"
    echo "  Stack Name: $STACK_NAME"
    echo "  Region: $REGION"
    echo "  Key Name: $KEY_NAME"
    echo "  Instance Type: $INSTANCE_TYPE"
    echo "  Environment: $ENVIRONMENT_NAME"
    echo "  Min/Max/Desired: $MIN_SIZE/$MAX_SIZE/$DESIRED_CAPACITY"
    echo
    
    # Pre-deployment checks
    check_aws_cli
    check_template
    validate_template
    validate_key_pair "$KEY_NAME"
    check_existing_stack
    
    # Deploy
    deploy_stack
    wait_for_stack
    
    # Show results
    echo
    echo "=========================================="
    show_outputs
    echo "=========================================="
    echo
    print_success "Deployment completed successfully!"
    print_status "You can now access your CoffeeShop application using the URL above."
}

# Run main function
main