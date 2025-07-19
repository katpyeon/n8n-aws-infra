# n8n AWS Infrastructure

English | [한국어](README.md)

One-click deployment of n8n server on AWS with secure external access using Terraform.

## 🏗️ AWS Stack Used

This project uses the following AWS services to deploy n8n server securely and scalably:

- **🖥️ EC2 (Elastic Compute Cloud)**: Virtual server running the n8n application
- **🌐 ALB (Application Load Balancer)**: Distributes external traffic to EC2 instances
- **🔒 ACM (AWS Certificate Manager)**: Automatic SSL/TLS certificate issuance for HTTPS
- **🌍 Route53**: Domain management and DNS routing
- **🛡️ Security Groups**: Network security rule configuration
- **🔧 VPC (Virtual Private Cloud)**: Isolated network environment setup
- **📦 Docker**: Containerization and deployment of n8n application

## 💰 Cost Information
- **Domain Purchase**: $15 (one-time)
- **Monthly Operating Cost**: $25~30 (excluding domain)
- **EC2**: t2.micro (cheapest plan)

## ⚠️ Prerequisites
1. **AWS Route53 domain purchase required** ($15)
2. **To increase EC2 specifications**, modify Docker settings in `user_data.sh` according to specifications
3. **Problem solving with AI assistance**
4. **All procedures based on macOS**

## 🚀 Deployment Steps

### 1. AWS IAM Creation

#### IAM User Creation (for CLI)
1. **AWS Console** → **IAM** → **Users** → **Create user**
2. **Username**: `terraform-user`
3. **Access Key Creation**: ✅ Check **Programmatic access**
4. **Permission Settings**: ✅ Select **Attach policies directly**
5. **Policy Attachment**: Attach the following 5 policies
6. **Creation Complete**: Save Access Key ID and Secret Access Key

#### Required Policies
- **AmazonEC2FullAccess**: EC2 instance creation and management
- **AmazonRoute53FullAccess**: Domain record registration
- **AWSCertificateManagerFullAccess**: SSL certificate issuance and validation
- **ElasticLoadBalancingFullAccess**: Load balancer creation and configuration
- **IAMReadOnlyAccess**: IAM user information query

### 2. AWS CLI Installation and Configuration

```bash
# Install via Homebrew
brew install awscli

# Configuration
aws configure --profile terraform-user
```

#### Configuration Information
```
AWS Access Key ID: [YOUR_ACCESS_KEY]
AWS Secret Access Key: [YOUR_SECRET_KEY]
Default region name: ap-northeast-2
Default output format: json
```

#### Configuration Verification
```bash
# Check configuration file
cat ~/.aws/credentials
```

### 3. Terraform Deployment

#### Environment Variable Setup
```bash
# 1. Create configuration file
cp terraform.tfvars.example terraform.tfvars

# 2. Modify with actual values
nano terraform.tfvars
```

#### Step-by-Step Verification (Recommended)
```bash
# Step 1: Networking
terraform apply -target=aws_vpc.main -target=aws_subnet.public -target=aws_subnet.public_2 -target=aws_internet_gateway.igw -target=aws_route_table.public -target=aws_route.default_route -target=aws_route_table_association.public_assoc -target=aws_route_table_association.public_assoc_2

# Step 2: Security Groups
terraform apply -target=aws_security_group.alb_sg -target=aws_security_group.ec2_sg

# Step 3: Load Balancer
terraform apply -target=aws_lb.alb -target=aws_lb_target_group.tg -target=aws_lb_listener.https

# Step 4: SSL Certificate
terraform apply -target=aws_acm_certificate.cert -target=aws_route53_record.cert_validation -target=aws_acm_certificate_validation.cert_validation

# Step 5: EC2 Instance
terraform apply -target=aws_instance.n8n -target=aws_lb_target_group_attachment.att

# Step 6: DNS Configuration
terraform apply -target=aws_route53_record.alias
```

#### URL Access and Verification
- **Terraform deployment completion doesn't mean immediate access**
- **Docker deployment must be completed**

##### Docker Deployment Status Check Method
1. **AWS Console** → **EC2** → **Instances** → Select created instance
2. **Connect** → **EC2 Instance Connect** → **Connect**
3. **Check Docker status with following commands in web console**:
   ```bash
   # Check Docker container status
   sudo docker ps
   
   # Check if n8n container is running
   sudo docker logs n8n
   
   # Check Docker image download status
   sudo docker images
   ```

##### When Access is Available
- **Access URL in browser**
- **If "Unsafe website" warning appears**:
  1. **AWS Console** → **Load Balancing** → **Target Groups** → Check status
  2. **If no issues**, waiting for certificate application (up to 24 hours)
  3. **"Proceed to unsafe site" allows n8n access**

#### Complete Deletion and Redeployment
```bash
# Complete deletion
terraform destroy

# Complete redeployment after deletion confirmation
terraform apply
```

---

<a href="https://www.buymeacoffee.com/katpyeon" target="_blank">
  <img src="https://cdn.buymeacoffee.com/buttons/v2/default-yellow.png" alt="Buy Me A Coffee" height="40" />
</a> 