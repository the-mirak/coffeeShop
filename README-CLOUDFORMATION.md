# CoffeeShop Application - AWS CloudFormation Deployment

This repository contains a comprehensive CloudFormation template and deployment tools for deploying the CoffeeShop FastAPI application on AWS.

## 📋 Overview

The CoffeeShop application is a FastAPI-based web application for managing a coffee shop's product catalog. This CloudFormation template provides a production-ready deployment with:

- **High Availability**: Multi-AZ deployment with Auto Scaling
- **Load Balancing**: Application Load Balancer for traffic distribution
- **Scalability**: Auto Scaling Group with configurable capacity
- **Storage**: DynamoDB for data and S3 for images
- **Security**: IAM roles with least privilege access

## 🏗️ Architecture

```
Internet Gateway
       |
Application Load Balancer (Multi-AZ)
       |
Auto Scaling Group
   |       |
EC2 Instances (FastAPI App)
   |       |
   |   DynamoDB Table
   |   (Product Data)
   |
S3 Bucket
(Product Images)
```

## 📁 Files Included

- `cloudformation-template.yaml` - Complete CloudFormation template
- `deploy.sh` - Automated deployment script
- `DEPLOYMENT_GUIDE.md` - Detailed deployment instructions
- `README-CLOUDFORMATION.md` - This file

## 🚀 Quick Start

### Prerequisites

1. AWS CLI installed and configured
2. EC2 Key Pair created in your target region
3. Appropriate AWS permissions for CloudFormation, EC2, DynamoDB, S3, and IAM

### Option 1: Automated Deployment (Recommended)

```bash
# Make the script executable
chmod +x deploy.sh

# Deploy with default settings
./deploy.sh --key-name your-key-pair-name

# Deploy with custom configuration
./deploy.sh \
  --key-name your-key-pair-name \
  --stack-name my-coffeeshop \
  --instance-type t3.small \
  --region us-west-2 \
  --desired-capacity 3
```

### Option 2: Manual AWS CLI Deployment

```bash
aws cloudformation create-stack \
  --stack-name coffeeshop-prod \
  --template-body file://cloudformation-template.yaml \
  --parameters ParameterKey=KeyName,ParameterValue=your-key-pair-name \
  --capabilities CAPABILITY_NAMED_IAM \
  --region us-east-1
```

### Option 3: AWS Console Deployment

1. Open AWS CloudFormation Console
2. Create new stack
3. Upload `cloudformation-template.yaml`
4. Fill in parameters (especially KeyName)
5. Deploy

## ⚙️ Configuration Parameters

| Parameter | Description | Default | Required |
|-----------|-------------|---------|----------|
| EnvironmentName | Prefix for resource names | CoffeeShop | No |
| InstanceType | EC2 instance type | t3.micro | No |
| KeyName | EC2 Key Pair name | - | **Yes** |
| MinSize | Minimum instances | 1 | No |
| MaxSize | Maximum instances | 3 | No |
| DesiredCapacity | Initial instances | 2 | No |

## 🔧 Deployment Script Options

The `deploy.sh` script supports the following options:

```bash
./deploy.sh [OPTIONS]

Options:
  -s, --stack-name NAME       CloudFormation stack name
  -r, --region REGION         AWS region
  -k, --key-name KEY          EC2 key pair name (required)
  -t, --instance-type TYPE    EC2 instance type
  -e, --environment NAME      Environment name prefix
  --min-size NUMBER           Minimum instances
  --max-size NUMBER           Maximum instances
  --desired-capacity NUMBER   Desired instances
  -h, --help                  Show help message
```

## 📊 Resources Created

### Networking
- VPC with DNS support
- 2 Public subnets across different AZs
- Internet Gateway
- Route tables and associations

### Storage
- DynamoDB table: `coffeeShopDB`
- S3 bucket: `coffeeshop-bucket-24`
- S3 bucket policy for public read access

### Compute
- Launch Template with user data script
- Auto Scaling Group (1-3 instances)
- Application Load Balancer
- Target Group with health checks

### Security
- IAM role for EC2 instances
- Security groups for ALB and EC2
- Instance profile for AWS service access

## 🔍 Post-Deployment

After successful deployment, you'll get outputs including:

- **LoadBalancerUrl**: Main application URL
- **LoadBalancerDNS**: ALB DNS name
- **DynamoDBTableName**: Database table name
- **S3BucketName**: Image storage bucket

### Application Endpoints

- **Home**: `http://your-alb-url/`
- **Menu**: `http://your-alb-url/menu`
- **Admin**: `http://your-alb-url/admin`
- **Health Check**: `http://your-alb-url/healthz`

## 🔧 Monitoring & Troubleshooting

### Health Checks
- Load balancer monitors `/healthz` endpoint
- Auto Scaling replaces unhealthy instances
- Target group shows instance health status

### Common Issues

1. **Stack Creation Fails**
   - Verify IAM permissions
   - Check key pair exists in target region
   - Ensure S3 bucket name is globally unique

2. **Application Not Accessible**
   - Check security group rules
   - Verify target group health
   - Review instance logs

3. **Database/Storage Issues**
   - Verify IAM role permissions
   - Check resource creation in console
   - Review application logs on instances

### Debugging Commands

```bash
# Check stack status
aws cloudformation describe-stacks --stack-name coffeeshop-prod

# View stack events
aws cloudformation describe-stack-events --stack-name coffeeshop-prod

# SSH to instance (replace with actual IP)
ssh -i your-key.pem ec2-user@instance-ip

# Check application service
sudo systemctl status coffeeShop.service
sudo journalctl -u coffeeShop.service -f
```

## 💰 Cost Considerations

**Estimated Monthly Costs (us-east-1):**
- EC2 t3.micro (2 instances): ~$17
- Application Load Balancer: ~$23
- DynamoDB (on-demand): Variable based on usage
- S3 storage: Variable based on image storage
- Data transfer: Variable based on traffic

**Total estimated**: ~$40-60/month for light usage

## 🔒 Security Best Practices

- Change SSH access from 0.0.0.0/0 to specific IP ranges
- Implement HTTPS with SSL certificates
- Enable CloudTrail for audit logging
- Regular security updates for EC2 instances
- Monitor AWS Config for compliance

## 🧹 Cleanup

To remove all resources:

```bash
# Using the deployment script
./deploy.sh --stack-name coffeeshop-prod --delete

# Or manually
aws cloudformation delete-stack --stack-name coffeeshop-prod
```

**Important**: Empty the S3 bucket before stack deletion if it contains objects.

## 📚 Additional Resources

- [AWS CloudFormation Documentation](https://docs.aws.amazon.com/cloudformation/)
- [FastAPI Documentation](https://fastapi.tiangolo.com/)
- [AWS Well-Architected Framework](https://aws.amazon.com/architecture/well-architected/)

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test the CloudFormation template
5. Submit a pull request

## 📄 License

This project is licensed under the MIT License - see the LICENSE file for details.

## 🆘 Support

For issues and questions:
1. Check the troubleshooting section in `DEPLOYMENT_GUIDE.md`
2. Review CloudFormation events in AWS Console
3. Check application logs on EC2 instances
4. Open an issue in the repository