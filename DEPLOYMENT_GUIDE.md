# CoffeeShop Application Deployment Guide

This guide explains how to deploy the CoffeeShop FastAPI application on AWS using the provided CloudFormation template.

## Prerequisites

1. **AWS Account**: You need an active AWS account with appropriate permissions
2. **EC2 Key Pair**: Create an EC2 key pair in your target region for SSH access
3. **AWS CLI** (optional): For command-line deployment
4. **Unique S3 Bucket Name**: The default bucket name `coffeeshop-bucket-24` must be globally unique

## Architecture Overview

The CloudFormation template creates the following AWS resources:

### Networking
- **VPC**: Custom VPC with DNS support
- **Subnets**: Two public subnets across different Availability Zones
- **Internet Gateway**: For public internet access
- **Route Tables**: Routing configuration for public subnets

### Storage
- **DynamoDB Table**: `coffeeShopDB` for storing product information
- **S3 Bucket**: `coffeeshop-bucket-24` for storing product images

### Compute
- **Launch Template**: EC2 instance configuration with user data script
- **Auto Scaling Group**: Manages EC2 instances across multiple AZs
- **Application Load Balancer**: Distributes traffic across instances
- **Target Group**: Health checks and routing for the application

### Security
- **IAM Role**: EC2 instances can access DynamoDB and S3
- **Security Groups**: Network access control for load balancer and web servers

## Deployment Steps

### Option 1: AWS Console Deployment

1. **Login to AWS Console**
   - Navigate to CloudFormation service
   - Select your target region (default: us-east-1)

2. **Create Stack**
   - Click "Create stack" → "With new resources (standard)"
   - Choose "Upload a template file"
   - Upload the `cloudformation-template.yaml` file

3. **Configure Parameters**
   - **Stack name**: Enter a unique name (e.g., `coffeeshop-prod`)
   - **EnvironmentName**: Prefix for resource names (default: CoffeeShop)
   - **InstanceType**: EC2 instance type (default: t3.micro)
   - **KeyName**: Select your EC2 key pair
   - **MinSize**: Minimum instances (default: 1)
   - **MaxSize**: Maximum instances (default: 3)
   - **DesiredCapacity**: Initial instances (default: 2)

4. **Deploy Stack**
   - Review configuration
   - Acknowledge IAM resource creation
   - Click "Create stack"

### Option 2: AWS CLI Deployment

```bash
# Deploy the stack
aws cloudformation create-stack \
  --stack-name coffeeshop-prod \
  --template-body file://cloudformation-template.yaml \
  --parameters ParameterKey=KeyName,ParameterValue=your-key-pair-name \
  --capabilities CAPABILITY_NAMED_IAM \
  --region us-east-1

# Monitor deployment progress
aws cloudformation describe-stacks \
  --stack-name coffeeshop-prod \
  --region us-east-1 \
  --query 'Stacks[0].StackStatus'
```

## Post-Deployment

### 1. Access the Application

After successful deployment:

1. **Get Load Balancer URL**:
   - Go to CloudFormation → Outputs tab
   - Copy the `LoadBalancerUrl` value
   - Access the application at: `http://your-alb-dns-name`

2. **Verify Application Health**:
   - Visit: `http://your-alb-dns-name/healthz`
   - Should return: `{"status": "healthy", "mode": "aws"}`

### 2. Application Features

- **Home Page**: `/` - Product showcase with quick order
- **Menu**: `/menu` - Full product catalog
- **Admin Panel**: `/admin` - Product management
- **Add Products**: `/add` - Create new products
- **About/Contact**: `/about`, `/contact` - Information pages

### 3. Admin Functions

The admin panel allows you to:
- View all products
- Add new products with images
- Edit existing products
- Delete products

Images are automatically uploaded to S3 and served via presigned URLs.

## Monitoring and Maintenance

### Health Checks
- Load balancer performs health checks on `/healthz`
- Unhealthy instances are automatically replaced
- Check Auto Scaling Group activity in EC2 console

### Logs
- Application logs: SSH to instances and check systemd logs
  ```bash
  sudo journalctl -u coffeeShop.service -f
  ```
- CloudWatch: Instance metrics and alarms (if configured)

### Scaling
- Auto Scaling Group automatically manages instance count
- Modify ASG parameters to change scaling behavior
- Monitor CloudWatch metrics for scaling decisions

## Troubleshooting

### Common Issues

1. **Stack Creation Fails**
   - Check IAM permissions
   - Verify key pair exists in target region
   - Ensure S3 bucket name is globally unique

2. **Application Not Accessible**
   - Verify security group rules
   - Check target group health status
   - Review instance user data logs

3. **Database Connection Issues**
   - Verify IAM role permissions
   - Check DynamoDB table exists
   - Review application logs

4. **Image Upload Problems**
   - Verify S3 bucket permissions
   - Check CORS configuration
   - Review IAM policies for S3 access

### Debugging Steps

1. **Check Instance Status**:
   ```bash
   # SSH to instance
   ssh -i your-key.pem ec2-user@instance-ip
   
   # Check service status
   sudo systemctl status coffeeShop.service
   
   # View logs
   sudo journalctl -u coffeeShop.service --no-pager
   ```

2. **Verify AWS Resources**:
   - DynamoDB table exists and accessible
   - S3 bucket exists with proper permissions
   - IAM role attached to instances

3. **Test Connectivity**:
   ```bash
   # Test from instance
   curl http://localhost:8080/healthz
   
   # Test database connection
   aws dynamodb scan --table-name coffeeShopDB --region us-east-1
   ```

## Cleanup

To remove all resources:

```bash
# Delete CloudFormation stack
aws cloudformation delete-stack \
  --stack-name coffeeshop-prod \
  --region us-east-1

# Monitor deletion
aws cloudformation describe-stacks \
  --stack-name coffeeshop-prod \
  --region us-east-1
```

**Note**: S3 bucket must be empty before stack deletion. Remove all objects first if needed.

## Cost Optimization

- Use `t3.micro` instances for development/testing
- Consider Reserved Instances for production workloads
- Monitor DynamoDB and S3 usage for cost optimization
- Set up CloudWatch billing alerts

## Security Considerations

- Change default SSH access (0.0.0.0/0) to specific IP ranges
- Implement HTTPS with SSL certificates
- Enable CloudTrail for audit logging
- Regular security updates for EC2 instances
- Consider using AWS Systems Manager for patch management

## Support

For issues with the application:
1. Check application logs on EC2 instances
2. Review CloudFormation events for deployment issues
3. Verify AWS service limits and quotas
4. Consult AWS documentation for service-specific troubleshooting