# Multi-Region Twingate VPN on AWS EC2

Deploy cost-effective, globally distributed Twingate VPN Connectors across multiple AWS EC2 instances using the official Twingate installation method. This provides a robust way to create Exit Networks with enterprise-grade security leveraging AWS's global infrastructure.

> **⚠️ Internal Use Only**: This project can only be used for personal or internal use. Please do not use this project or Twingate to offer a commercial VPN service. Also note that bandwidth usage through Twingate infrastructure is subject to Twingate's [Fair Use Policy](https://www.twingate.com/terms/sa).

## 🏗️ Architecture

```text
┌─────────────────────┐    ┌─────────────────────┐    ┌─────────────────────┐
│   us-east-1 Region  │    │   eu-west-1 Region  │    │ ap-southeast-1 Reg  │
│                     │    │                     │    │                     │
│ ┌─────────────────┐ │    │ ┌─────────────────┐ │    │ ┌─────────────────┐ │
│ │  EC2 Instance   │ │    │ │  EC2 Instance   │ │    │ │  EC2 Instance   │ │
│ │  us-east-1-vpn  │ │    │ │  eu-west-1-vpn  │ │    │ │ap-southeast-1-vp│ │
│ │                 │ │    │ │                 │ │    │ │                 │ │
│ │  Twingate       │ │    │ │  Twingate       │ │    │ │  Twingate       │ │
│ │  Connector      │ │    │ │  Connector      │ │    │ │  Connector      │ │
│ └─────────────────┘ │    │ └─────────────────┘ │    │ └─────────────────┘ │
│                     │    │                     │    │                     │
│  VPC + Security Grp │    │  VPC + Security Grp │    │  VPC + Security Grp │
└─────────────────────┘    └─────────────────────┘    └─────────────────────┘
         │                           │                           │
         └───────────────────────────┼───────────────────────────┘
                                     │
                        ┌─────────────────────────┐
                        │   Twingate Cloud        │
                        │   aws_us-east-1 Network │
                        │   aws_eu-west-1 Network │
                        │   aws_ap-southeast-1    │
                        └─────────────────────────┘
```

### Key Design Principles

- **Per-Region Exit Networks**: Each region gets its own Twingate remote network (`aws_{region}`)
- **Zero-Trust Security**: Completely locked-down security groups with no inbound ports
- **Official Installation**: Uses Twingate's recommended APT package and systemd service
- **Cloud-Init Automation**: Complete Connector setup without manual intervention
- **Cost Optimization**: Uses minimal instance sizes (t3.micro) for cost effectiveness
- **High Availability**: Support for multiple instances per region
- **AWS Native**: Leverages VPCs, security groups, and AWS networking

## ✨ Key Features

✅ **Official Integration**: Uses Twingate's recommended APT package installation  
✅ **Zero-Trust Security**: No SSH, no inbound ports - access only via Twingate  
✅ **Automatic Updates**: Built-in security updates for system and Twingate packages  
✅ **Production Ready**: Systemd service management with restart policies and logging  
✅ **Multi-Region Support**: Deploy across any AWS region globally  
✅ **Scalable**: Easy to add/remove regions and scale instances per region  
✅ **Infrastructure as Code**: Complete Terraform automation with proper state management  
✅ **AWS Best Practices**: VPC isolation, security groups, proper IAM structure  

## 📋 Prerequisites

### Required Tools

- [Terraform](https://www.terraform.io/downloads.html) >= 1.0
- AWS account with programmatic access
- **Twingate Home** or other subscription plan that includes Exit Networks (not available on Starter plan)
- Twingate account with Admin privileges

### Required Credentials

- **AWS Access Key ID**: Generate from AWS IAM Console
- **AWS Secret Access Key**: Generated with Access Key ID
- **Twingate Account**: Admin access to create API tokens
- **Twingate API Token**: Generate from Twingate Admin Console → Settings → API
- **Twingate Network Name**: Your tenant name (e.g., `company.twingate.com` → `company`)

### Optional (for debugging)

- EC2 Key Pair configured in AWS (not recommended for production)

## 🚀 Quick Start

### 1. Clone and Configure

```bash
# Clone the repository
git clone https://github.com/Twingate-Community/diy-vpn.git
cd diy-vpn/aws/droplet

# Copy the example configuration
cp terraform.tfvars.example terraform.tfvars
```

### 2. Edit Configuration

Edit `terraform.tfvars` with your credentials and desired instance configuration:

```hcl
# Required: AWS credentials
aws_access_key = "AKIAIOSFODNN7EXAMPLE"
aws_secret_key = "wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY"
aws_region     = "us-east-1"  # Primary region for provider

# Required: Twingate credentials
tg_api_token = "your_twingate_api_token_here"
tg_network   = "your_twingate_network_name"

# Configure EC2 instances across regions
instances = {
  "virginia-vpn" = {
    region        = "us-east-1"
    instance_type = "t3.micro"
    count         = 1
    ami           = "ami-0c02fb55b34e3a85c"  # Ubuntu 24.04 LTS
  }
  "oregon-vpn" = {
    region        = "us-west-2"
    instance_type = "t3.micro"
    count         = 1
    ami           = "ami-05134c8ef96964280"  # Ubuntu 24.04 LTS
  }
  "ireland-vpn" = {
    region        = "eu-west-1"
    instance_type = "t3.micro"
    count         = 2  # Multiple instances for HA
    ami           = "ami-0c38b837cd80f13bb"  # Ubuntu 24.04 LTS
  }
}

# Optional: SSH key pair for emergency console access only
ssh_key_name = ""  # Leave empty for maximum security

# Environment label
environment = "production"
```

### 3. Deploy Infrastructure

```bash
# Initialize Terraform
terraform init

# Review the deployment plan
terraform plan

# Deploy the infrastructure (takes 3-5 minutes)
terraform apply
```

### 4. Verify Deployment

**Check Terraform Outputs:**

```bash
terraform output
```

**Verify in Twingate Admin Console:**

1. **Remote Networks**: Should see networks like `aws_us-east-1`, `aws_us-west-2`, `aws_eu-west-1`
2. **Connectors**: Should show online Connectors for each EC2 instance
3. **Labels**: Connectors properly labeled with region, deployment method, and environment

**Expected Output Example:**

```text
deployment_summary = {
  "connectors" = 4
  "environment" = "production"
  "remote_networks" = 3
  "total_instances" = 4
  "twingate_network" = "yourcompany"
  "unique_regions" = 3
}
```

## Complete Shutdown

To completely shutdown the VPN infrastructure:

```bash
terraform destroy
```

## 🔧 Configuration Reference

### Instance Configuration Options

Each instance entry in the `instances` map supports these parameters:

```hcl
"instance-name" = {
  region        = "us-east-1"              # Required: AWS region
  instance_type = "t3.micro"               # Optional: Instance type (default: t3.micro)
  count         = 1                        # Optional: Number of instances (default: 1)
  ami           = "ami-0c02fb55b34e3a85c"  # Optional: AMI ID (default: Ubuntu 24.04 in us-east-1)
}
```

### Supported AWS Regions

| Region | Location | Code | Typical Use Case |
|--------|----------|------|------------------|
| **US East** | | | |
| N. Virginia | USA East | `us-east-1` | East Coast users, lowest latency to many services |
| Ohio | USA Central | `us-east-2` | Central USA, disaster recovery from us-east-1 |
| **US West** | | | |
| N. California | USA West | `us-west-1` | West Coast users |
| Oregon | USA West | `us-west-2` | West Coast users, lower cost than us-west-1 |
| **Europe** | | | |
| Ireland | Europe | `eu-west-1` | UK/Western Europe users |
| London | UK | `eu-west-2` | UK users, data residency |
| Paris | France | `eu-west-3` | France, data residency |
| Frankfurt | Germany | `eu-central-1` | Central/Eastern Europe |
| **Asia Pacific** | | | |
| Singapore | Southeast Asia | `ap-southeast-1` | Southeast Asia users |
| Sydney | Australia | `ap-southeast-2` | Australia/New Zealand users |
| Tokyo | Japan | `ap-northeast-1` | Japan/East Asia users |
| Seoul | South Korea | `ap-northeast-2` | Korea users |
| Mumbai | India | `ap-south-1` | India/South Asia users |
| **Other** | | | |
| São Paulo | Brazil | `sa-east-1` | South America users |
| Canada | Canada | `ca-central-1` | Canadian users, data residency |

### Instance Sizes

| Type | vCPUs | Memory | Network | Cost/Month* | Recommended For |
|------|-------|--------|---------|-------------|-----------------|
| `t3.micro` | 2 | 1GB | Up to 5 Gbps | ~$7.50 | **Recommended**: Most VPN traffic |
| `t3.small` | 2 | 2GB | Up to 5 Gbps | ~$15 | High traffic or multiple users |
| `t3.medium` | 2 | 4GB | Up to 5 Gbps | ~$30 | Very high traffic |

*Approximate costs, varies by region. Check [AWS EC2 Pricing](https://aws.amazon.com/ec2/pricing/) for current rates.

> **💡 Cost Tip**: Start with `t3.micro` - it handles most VPN workloads efficiently. T3 instances use burstable CPU credits.

### Ubuntu 24.04 LTS AMI IDs by Region

| Region | AMI ID | 
|--------|--------|
| us-east-1 | ami-0c02fb55b34e3a85c |
| us-east-2 | ami-0a0e5d9c7acc336f1 |
| us-west-1 | ami-0ec14a68621e2d49e |
| us-west-2 | ami-05134c8ef96964280 |
| eu-west-1 | ami-0c38b837cd80f13bb |
| eu-west-2 | ami-0b9932f4918a00c4f |
| eu-west-3 | ami-0a2d839ee977f9b9f |
| eu-central-1 | ami-0a628e1e89aaedf80 |
| ap-south-1 | ami-0dee22c13ea7a9a67 |
| ap-southeast-1 | ami-060e277c0d4cce553 |
| ap-southeast-2 | ami-0146fc9ad419e2cfd |
| ap-northeast-1 | ami-0f2dd5fc989207c82 |
| ap-northeast-2 | ami-0c4c3c8e6e6d6e9f8 |
| sa-east-1 | ami-0c820c196a818d66a |
| ca-central-1 | ami-0c3e9e5f8f7e8e6a5 |

> **Note**: AMI IDs are region-specific. These are for Ubuntu 24.04 LTS. Use the AWS Console or CLI to find the latest AMIs.

### Security Configuration

**Zero-Trust Security (Default - recommended):**

```hcl
# Maximum security - no direct access
ssh_key_name = ""                  # No SSH key
environment  = "production"        # Production security settings
```

**Emergency Access (Optional - for debugging only):**

```hcl
# Emergency console access via AWS Systems Manager or EC2 console
ssh_key_name = "your-key-pair"     # EC2 key pair for emergency access
environment  = "development"        # Development settings
```

> **⚠️ Security Note**: Even with SSH keys, network SSH is completely blocked by security groups. Access only via AWS Systems Manager Session Manager.

## 📋 Resource Management

### Naming Conventions

| Resource Type | Naming Pattern | Examples |
|--------------|----------------|----------|
| **Single Instance** | `{region}-vpn` | `us-east-1-vpn`, `eu-west-1-vpn` |
| **Multiple Instances** | `{region}-vpn-{nn}` | `us-west-2-vpn-01`, `us-west-2-vpn-02` |
| **Remote Networks** | `aws_{region}` | `aws_us-east-1`, `aws_eu-west-1` |
| **Connectors** | Same as instance | `us-east-1-vpn`, `us-west-2-vpn-01` |
| **VPCs** | `twingate-vpn-{region}` | `twingate-vpn-us-east-1` |
| **Security Groups** | `twingate-vpn-sg-{region}` | `twingate-vpn-sg-us-east-1` |

### Tags Applied to All Resources

- `Name` - Resource name
- `Environment` - Environment designation
- `ManagedBy` - Always "terraform"
- `Purpose` - "twingate-vpn"
- `Region` - AWS region

## 🔧 Operations & Maintenance

### Health Monitoring

**Via Terraform Outputs:**

```bash
# Check deployment status
terraform output deployment_summary

# Get instance information
terraform output instances

# View remote networks
terraform output twingate_remote_networks

# View VPC information
terraform output vpc_info
```

**Via Twingate Admin Console:**

1. Navigate to "Networks" → Check Connector status (should be green/online)
2. Navigate to "Analytics" → Monitor Connector traffic and health
3. Check Connector labels for deployment metadata

**Via AWS Console:**

1. EC2 → Instances → View instance status and resource usage
2. VPC → Security Groups → Verify security group rules
3. Systems Manager → Session Manager for emergency console access

### Service Management

Access instances via Twingate network, AWS Systems Manager, or EC2 console:

```bash
# Connect via AWS Systems Manager Session Manager (no SSH key needed)
aws ssm start-session --target i-1234567890abcdef0

# Once connected, check Connector service status
systemctl status twingate-connector

# View real-time logs
journalctl -u twingate-connector -f

# Restart Connector if needed
sudo systemctl restart twingate-connector

# Check system health
htop                    # Resource usage
df -h                   # Disk space
free -h                 # Memory usage
```

### Automatic Maintenance

**System Updates:**

- **Security updates**: Applied automatically via `unattended-upgrades`
- **Twingate updates**: Official APT repository ensures latest version
- **Reboot handling**: Automatic reboot if required by kernel updates

**Service Management:**

- **Auto-restart**: Service automatically restarts on failure
- **Logging**: Structured logs via systemd journal
- **Resource limits**: Proper ulimits and systemd limits applied

### Scaling Operations

**Adding a New Region:**

```hcl
instances = {
  # ... existing instances ...
  "tokyo-vpn" = {
    region        = "ap-northeast-1"
    instance_type = "t3.micro"
    count         = 1
    ami           = "ami-0f2dd5fc989207c82"  # Ubuntu 24.04 LTS for Tokyo
  }
}
```

**Scaling Existing Region (High Availability):**

```hcl
"oregon-vpn" = {
  region        = "us-west-2"
  instance_type = "t3.micro"
  count         = 3  # Increased from 1 for HA
  ami           = "ami-05134c8ef96964280"
}
```

**Upgrading Instance Size:**

```hcl
"virginia-vpn" = {
  region        = "us-east-1"
  instance_type = "t3.small"  # Upgraded from t3.micro
  count         = 1
  ami           = "ami-0c02fb55b34e3a85c"
}
```

> **⚠️ Note**: Changing instance type requires recreation (brief downtime). Consider creating new instances first for zero-downtime upgrades.

## 🔍 Troubleshooting

### Common Issues & Solutions

| Issue | Symptoms | Solution |
|-------|----------|----------|
| **Connector Offline** | Connector shows offline in Twingate Console | Check cloud-init logs, verify tokens, restart service |
| **Instance Creation Fails** | Terraform apply fails during instance creation | Check AWS credentials, region availability, service quotas |
| **Invalid API Tokens** | Authentication errors in logs | Verify tokens in respective consoles, check expiry |
| **High Resource Usage** | Instance performance issues | Monitor with CloudWatch, consider upgrading instance type |
| **Network Connectivity Issues** | Slow or failed connections | Check regional latency, verify security groups, check VPC routing |
| **AMI Not Found** | Terraform error about AMI | Update AMI ID for specific region from AWS Console |

### Diagnostic Commands

**Via AWS Systems Manager or EC2 Console:**

```bash
# Check cloud-init completion and logs
sudo tail -f /var/log/cloud-init-output.log

# Monitor Twingate Connector service
sudo systemctl status twingate-connector
sudo journalctl -u twingate-connector -f --since "1 hour ago"

# System health checks
htop                          # CPU and memory usage
df -h                         # Disk usage
free -h                       # Memory details
ss -tuln                      # Network connections (should be minimal)
dmesg | tail -20             # Recent kernel messages

# Check Twingate configuration
sudo cat /etc/twingate/connector.conf  # Configuration file (contains tokens)
```

**Via Terraform:**

```bash
# Check deployment status
terraform output deployment_summary
terraform output instances

# Validate configuration
terraform validate
terraform plan

# Refresh state and check for drift
terraform refresh
```

**Via AWS CLI:**

```bash
# Check instance status
aws ec2 describe-instances --filters "Name=tag:Purpose,Values=twingate-vpn" \
  --query 'Reservations[*].Instances[*].[InstanceId,State.Name,PublicIpAddress]' \
  --output table

# View CloudWatch metrics
aws cloudwatch get-metric-statistics --namespace AWS/EC2 \
  --metric-name CPUUtilization --dimensions Name=InstanceId,Value=i-1234567890 \
  --statistics Average --start-time 2024-01-01T00:00:00Z --end-time 2024-01-01T23:59:59Z \
  --period 3600
```

### Performance Tuning

**For High Traffic Scenarios:**

1. **Upgrade Instance Type**:

   ```hcl
   instance_type = "t3.small"  # or "t3.medium"
   ```

2. **Add Multiple Instances per Region**:

   ```hcl
   count = 2  # or more for load distribution
   ```

3. **Monitor with CloudWatch**: Set up CloudWatch alarms for CPU, memory, and network

4. **Enable Enhanced Monitoring**: For detailed metrics

### Emergency Procedures

**If Connector Goes Offline:**

1. Check Twingate Admin Console for Connector status
2. Access via AWS Systems Manager Session Manager
3. Restart Connector service: `sudo systemctl restart twingate-connector`
4. Check logs: `sudo journalctl -u twingate-connector -n 100`
5. If persistent, recreate instance: `terraform taint aws_instance.twingate_connectors["instance-name"]`

**Complete Recovery:**

```bash
# Destroy and recreate specific instance
terraform destroy -target="aws_instance.twingate_connectors[\"us-east-1-vpn\"]"
terraform apply

# Or recreate everything
terraform destroy
terraform apply
```

## 🧹 Cleanup & Decommissioning

### Selective Cleanup

**Remove specific region:**

```hcl
# Comment out or remove from terraform.tfvars
instances = {
  # "virginia-vpn" = {  # Commented out
  #   region        = "us-east-1"
  #   instance_type = "t3.micro"
  #   count         = 1
  # }
  "oregon-vpn" = {
    region        = "us-west-2"
    instance_type = "t3.micro"
    count         = 1
    ami           = "ami-05134c8ef96964280"
  }
}
```

Then run:

```bash
terraform apply  # Will destroy the removed resources
```

### Complete Cleanup

```bash
# Destroy all resources
terraform destroy

# Confirm all resources removed
terraform show
```

**Resources Removed:**

- ✅ EC2 instances
- ✅ VPCs, subnets, and internet gateways
- ✅ Security groups
- ✅ Route tables and associations
- ✅ Twingate remote networks
- ✅ Twingate Connectors
- ✅ Twingate Connector tokens

## 🔒 Security Best Practices

### Production Security Checklist

- [ ] **No SSH Keys**: Use `ssh_key_name = ""` for maximum security
- [ ] **Use IAM Roles**: Consider using IAM instance roles instead of access keys
- [ ] **Token Rotation**: Regularly rotate Twingate and AWS API tokens
- [ ] **State File Security**: Secure Terraform state file (contains sensitive tokens)
- [ ] **Network Monitoring**: Monitor Twingate Analytics for unusual activity
- [ ] **CloudWatch Alarms**: Set up alarms for instance health and performance
- [ ] **Update Management**: Verify automatic updates are working
- [ ] **Backup Strategy**: Document recovery procedures
- [ ] **VPC Flow Logs**: Enable for security monitoring (optional)
- [ ] **AWS Organizations**: Use AWS Organizations for multi-account management

### Advanced Security Configuration

**State File Encryption:**

```hcl
terraform {
  backend "s3" {
    bucket         = "your-terraform-state"
    key            = "twingate-vpn/terraform.tfstate"
    region         = "us-east-1"
    encrypt        = true
    dynamodb_table = "terraform-state-lock"
  }
}
```

**Token Management:**

```bash
# Use environment variables instead of tfvars for CI/CD
export TF_VAR_aws_access_key="your_access_key"
export TF_VAR_aws_secret_key="your_secret_key"
export TF_VAR_tg_api_token="your_tg_token"
```

**IAM Policy for Terraform (Least Privilege):**

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "ec2:*",
        "vpc:*"
      ],
      "Resource": "*",
      "Condition": {
        "StringEquals": {
          "aws:RequestedRegion": ["us-east-1", "us-west-2", "eu-west-1"]
        }
      }
    }
  ]
}
```

## 💰 Cost Optimization

### Estimated Monthly Costs

| Configuration | Instances | Cost/Month* |
|--------------|-----------|-------------|
| **Minimal** | 3 t3.micro (3 regions) | ~$22.50 |
| **Standard** | 6 t3.micro (6 regions) | ~$45 |
| **High Availability** | 10 t3.micro (5 regions × 2) | ~$75 |
| **Enterprise** | 15 t3.small (5 regions × 3) | ~$225 |

*Approximate costs for US regions. Add data transfer costs (~$0.09/GB out).

### Cost Reduction Tips

1. **Use Savings Plans**: AWS Compute Savings Plans can save up to 72%
2. **Reserved Instances**: For long-term deployments (1-3 years)
3. **Spot Instances**: Not recommended for VPN (may be terminated)
4. **Right-Sizing**: Start with t3.micro and scale only if needed
5. **Regional Selection**: Some regions are cheaper (us-east-1, us-west-2)
6. **Data Transfer**: Keep connectors close to users to minimize data transfer
7. **CloudWatch**: Use only essential metrics to reduce monitoring costs

## 📞 Support & Resources

### Documentation Links

- 📖 [Twingate Connector Documentation](https://docs.twingate.com/docs/connector-deployment-guides)
- ☁️ [AWS EC2 Documentation](https://docs.aws.amazon.com/ec2/)
- 🏗️ [Terraform AWS Provider](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
- 💰 [AWS Pricing Calculator](https://calculator.aws/)

### Community Support

- 💬 [Twingate Community Forum](https://community.twingate.com/)
- 🐛 [Report Issues](https://github.com/Twingate-Community/diy-vpn/issues)
- 📧 [Twingate Support](https://www.twingate.com/support)
- 🎓 [AWS Support](https://aws.amazon.com/support/)

### Getting Help

**For Infrastructure Issues:**

1. Check troubleshooting section above
2. Review Terraform logs: `terraform apply -auto-approve -no-color 2>&1 | tee terraform.log`
3. Post logs in GitHub issues (remove sensitive tokens)

**For Twingate Issues:**

1. Check Twingate Admin Console logs
2. Review Connector service logs
3. Contact Twingate support with Connector IDs

**For AWS Issues:**

1. Check AWS CloudWatch logs
2. Review EC2 instance system logs
3. Contact AWS support or post in AWS forums

---

🎉 **Congratulations!** You now have a production-ready, globally distributed VPN infrastructure on AWS powered by Twingate's zero-trust networking.
