# Multi-Cluster Twingate VPN on AWS EKS

Deploy enterprise-grade Twingate Exit Networks across multiple AWS Elastic Kubernetes Service (EKS) clusters for high availability and advanced container orchestration. This solution provides access to existing cluster resources and keeps your VPN infrastructure co-located with your applications on AWS's managed Kubernetes platform.

> **⚠️ Internal Use Only**: This project can only be used for personal or internal use. Please do not use this project or Twingate to offer a commercial VPN service. Also note that bandwidth usage through Twingate infrastructure is subject to Twingate's [Fair Use Policy](https://www.twingate.com/terms/sa).

## 🏗️ Architecture

```text
┌─────────────────────────────────┐    ┌─────────────────────────────────┐    ┌─────────────────────────────────┐
│          NYC1 Cluster           │    │          AMS3 Cluster           │    │          SGP1 Cluster           │
│                                 │    │                                 │    │                                 │
│ ┌─────────────────────────────┐ │    │ ┌─────────────────────────────┐ │    │ ┌─────────────────────────────┐ │
│ │       Twingate Operator     │ │    │ │       Twingate Operator     │ │    │ │       Twingate Operator     │ │
│ │                             │ │    │ │                             │ │    │ │                             │ │
│ │  ┌─────────┐ ┌─────────┐    │ │    │ │  ┌─────────┐ ┌─────────┐    │ │    │ │  ┌─────────┐ ┌─────────┐    │ │
│ │  │Connector│ │Connector│    │ │    │ │  │Connector│ │Connector│    │ │    │ │  │Connector│ │Connector│    │ │
│ │  │  Pod 1  │ │  Pod 2  │    │ │    │ │  │  Pod 1  │ │  Pod 2  │    │ │    │ │  │  Pod 1  │ │  Pod 2  │    │ │
│ │  └─────────┘ └─────────┘    │ │    │ │  └─────────┘ └─────────┘    │ │    │ │  └─────────┘ └─────────┘    │ │
│ └─────────────────────────────┘ │    │ └─────────────────────────────┘ │    │ └─────────────────────────────┘ │
│                                 │    │                                 │    │                                 │
│ Cluster Nodes: 1-3 nodes        │    │ Cluster Nodes: 1-3 nodes        │    │ Cluster Nodes: 1-3 nodes        │
└─────────────────────────────────┘    └─────────────────────────────────┘    └─────────────────────────────────┘
           │                                        │                                        │
           └────────────────────────────────────────┼────────────────────────────────────────┘
                                                    │
                                       ┌─────────────────────┐
                                       │  Twingate Cloud     │
                                       │  do_nyc1 Network    │
                                       │  do_ams3 Network    │
                                       │  do_sgp1 Network    │
                                       └─────────────────────┘
```

## ✨ Key Features

✅ **Enterprise-Grade**: AWS EKS managed Kubernetes with Twingate operator orchestration  
✅ **Resource Access**: Access to existing cluster resources and services  
✅ **High Availability**: Multi-AZ node groups with pod distribution  
✅ **Production Security**: Non-root containers, IAM roles, security contexts, and RBAC  
✅ **Observability**: Structured logging, metrics, and health checks  
✅ **Cloud-Native**: Uses AWS and Kubernetes best practices  
✅ **CI/CD Integration**: Suitable for GitOps workflows and automated deployments  
✅ **AWS Native**: Leverages VPCs, IAM, and AWS networking infrastructure  

## 📋 Prerequisites

### Required Tools

- [Terraform](https://www.terraform.io/downloads.html) >= 1.0
- [AWS CLI](https://aws.amazon.com/cli/) >= 2.0 (for kubeconfig management)
- [kubectl](https://kubernetes.io/docs/tasks/tools/install-kubectl/) >= 1.25
- [helm](https://helm.sh/docs/intro/install/) >= 3.8
- **Twingate Home** or higher subscription plan (Exit Networks not available on Starter plan)

### Required Credentials

- **AWS Credentials**: One of the following:
  - **IAM User Keys**: Access Key ID and Secret Access Key (starts with `AKIA...`)
  - **SSO/Temporary Credentials**: Access Key ID (starts with `ASIA...`), Secret Access Key, and Session Token
- **Twingate Account**: Admin access to create API tokens
- **Twingate API Token**: Generate from Twingate Admin Console → Settings → API
- **Twingate Network Name**: Your tenant name (e.g., `company.twingate.com` → `company`)

> **💡 Tip**: If using AWS SSO, export credentials using `aws configure export-credentials` to get temporary credentials including the session token.

### System Requirements

- **Local Machine**: A machine with this repo cloned to it
- **Network Access**: Ability to connect to AWS services
- **AWS Quota**: Each EKS cluster requires a VPC (default limit: 5 VPCs per region)

## 🚀 Quick Start

### 1. Clone and Configure

```bash
# Clone the repository
git clone https://github.com/Twingate-Community/diy-vpn.git
cd diy-vpn/aws/kubernetes

# Copy the example configuration
cp terraform.tfvars.example terraform.tfvars
```

Edit `terraform.tfvars` to include your credentials and desired cluster configuration:

```hcl
# Required: AWS credentials
aws_access_key = "your_aws_access_key_here"     # AKIA... for permanent, ASIA... for temporary
aws_secret_key = "your_aws_secret_key_here"
aws_session_token = ""  # Required only for temporary credentials (AWS SSO, assumed roles)

# Required: Twingate credentials
tg_api_token = "your_twingate_api_token"
tg_network   = "your_twingate_network"  # e.g., company (from company.twingate.com)

# Configure EKS clusters across regions
clusters = {
  "virginia-vpn-cluster" = {
    region        = "us-east-1"
    instance_type = "t3.medium"
    node_count    = 2
  }
  "oregon-vpn-cluster" = {
    region        = "us-west-2"
    instance_type = "t3.medium"
    node_count    = 2
  }
  # Add more clusters as needed (mind VPC limits)
}

# Environment label
environment = "production"
```

### 2. Deploy Infrastructure

```bash
# Initialize Terraform
terraform init

# Review the deployment plan
terraform plan

# Deploy the infrastructure (takes 15-20 minutes for EKS clusters)
terraform apply
```

The deployment process will:

1. Create Twingate Exit Networks (one per region)
2. Create VPCs with subnets, Internet Gateways, and route tables
3. Create IAM roles for EKS clusters and node groups
4. Deploy EKS clusters (v1.31) in specified regions
5. Deploy node groups with managed EC2 instances
6. Configure kubectl access for each cluster
7. Deploy Twingate operator via Helm to each cluster
8. Create Twingate Connectors in each cluster

### 3. Verify Deployment

After deployment, check the status:

```bash
# List all clusters
terraform output cluster_names

# Get kubeconfig commands for all clusters
terraform output kubeconfig_commands

# Configure kubectl for a specific cluster
aws eks update-kubeconfig --name virginia-vpn-cluster --region us-east-1

# Check connector status in the cluster
kubectl get twingateconnectors -n twingate

# View deployment summary
terraform output deployment_summary
```

**Expected Output Example:**

```text
deployment_summary = {
  "environment" = "production"
  "kubernetes_version" = "1.31"
  "remote_networks" = 3
  "total_clusters" = 3
  "twingate_network" = "yourcompany"
  "unique_regions" = 3
}
```

## Configuration Options

### Cluster Configuration

Each cluster in the `clusters` variable supports these options:

- `region` (required): AWS region code (e.g., `us-east-1`, `eu-west-1`)
- `instance_type` (optional): EC2 instance type for nodes (default: `t3.medium`)
- `node_count` (optional): Desired number of nodes (default: 2)

### Supported AWS Regions

You can deploy EKS clusters to any AWS region. Common choices:

| Region | Location | Code |
|--------|----------|------|
| **US East** | N. Virginia | `us-east-1` |
| **US East** | Ohio | `us-east-2` |
| **US West** | N. California | `us-west-1` |
| **US West** | Oregon | `us-west-2` |
| **Europe** | Ireland | `eu-west-1` |
| **Europe** | London | `eu-west-2` |
| **Europe** | Frankfurt | `eu-central-1` |
| **Asia Pacific** | Singapore | `ap-southeast-1` |
| **Asia Pacific** | Tokyo | `ap-northeast-1` |
| **Asia Pacific** | Sydney | `ap-southeast-2` |

> **⚠️ VPC Quota**: Each EKS cluster creates a VPC. AWS default limit is 5 VPCs per account. Request a quota increase if needed.

### Instance Types

| Type | vCPUs | Memory | Recommended For |
|------|-------|--------|------------------|
| `t3.small` | 2 | 2GB | Light traffic |
| `t3.medium` | 2 | 4GB | **Recommended**: Most workloads |
| `t3.large` | 2 | 8GB | High traffic |

*Check [AWS EC2 Pricing](https://aws.amazon.com/ec2/pricing/) for instance pricing.

## Adding a New Cluster

To add a new cluster, add an entry to the `clusters` variable in your `terraform.tfvars`:

```hcl
clusters = {
  # ... existing clusters ...
  "tokyo-vpn-cluster" = {
    region        = "ap-northeast-1"
    instance_type = "t3.medium"
    node_count    = 2
  }
}
```

Then run `terraform apply` to deploy the new cluster (takes ~15-20 minutes).

## Complete Shutdown

To completely shutdown the VPN infrastructure:

```bash
terraform destroy
```

> **Note**: EKS cluster deletion can take 10-15 minutes.

## Removing a Cluster

Remove the cluster entry from the `clusters` variable and run `terraform apply`. Terraform will destroy the cluster and its associated resources.

## File Structure

```bash
aws/kubernetes/
├── main.tf                    # EKS clusters, VPCs, IAM roles, node groups
├── deploy.tf                  # Helm deployment automation
├── variables.tf               # Input variables
├── outputs.tf                 # Output values
├── providers.tf               # AWS and Twingate providers
├── terraform.tfvars.example  # Example configuration
└── README.md                  # This file
```

## Outputs

- `clusters`: Detailed information about all deployed clusters (sensitive)
- `cluster_names`: List of all cluster names
- `kubeconfig_commands`: AWS CLI commands to configure kubectl for each cluster
- `twingate_remote_network_ids`: Twingate remote network IDs per cluster
- `vpc_info`: VPC details including IDs and CIDR blocks
- `node_group_info`: Node group status and configuration
- `deployment_summary`: Overall deployment statistics
