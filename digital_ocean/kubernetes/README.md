# Multi-Cluster Twingate VPN on DigitalOcean Kubernetes

Deploy enterprise-grade Twingate Exit Networks across multiple DigitalOcean Kubernetes clusters for auto-scaling, high availability, and advanced container orchestration. This solution provides maximum flexibility and scalability for large-scale VPN deployments.

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
│ Auto-Scaling: 1-3 nodes         │    │ Auto-Scaling: 1-3 nodes         │    │ Auto-Scaling: 1-3 nodes         │
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

✅ **Enterprise-Grade**: Kubernetes operator with advanced orchestration capabilities  
✅ **Auto-Scaling**: Dynamic node and pod scaling based on demand  
✅ **High Availability**: Multi-node clusters with pod distribution and anti-affinity  
✅ **Production Security**: Non-root containers, security contexts, and RBAC  
✅ **Observability**: Structured logging, metrics, and health checks  
✅ **Cloud-Native**: Uses Kubernetes best practices and cloud-native patterns  
✅ **CI/CD Integration**: Suitable for GitOps workflows and automated deployments  
✅ **Advanced Networking**: Service mesh ready with proper network policies  

## 📋 Prerequisites

### Required Tools

- [Terraform](https://www.terraform.io/downloads.html) >= 1.0
- [doctl](https://docs.digitalocean.com/reference/doctl/how-to/install/) (DigitalOcean CLI)
- [kubectl](https://kubernetes.io/docs/tasks/tools/install-kubectl/) >= 1.25
- [helm](https://helm.sh/docs/intro/install/) >= 3.8

### Required Credentials

- **DigitalOcean API Token**: Generate from [DigitalOcean Control Panel](https://cloud.digitalocean.com/account/api/tokens)
- **Twingate Home** or higher subscription plan (Exit Networks not available on Starter plan)
- **Twingate API Token**: Generate from Twingate Admin Console → Settings → API
- **Twingate Network Name**: Your tenant name (e.g., `company.twingate.com` → `company`)

### System Requirements

- **Local Machine**: A machine with this repo cloned to it
- **Network Access**: Ability to connect to Digital Ocean

## 🚀 Quick Start

### 1. Clone and Configure

```bash
# Clone the repository
git clone https://github.com/Twingate-Community/diy-vpn.git
cd diy-vpn/digital_ocean/kubernetes

# Copy the example configuration
cp terraform.tfvars.example terraform.tfvars
```

Edit `terraform.tfvars` to include your API tokens and desired cluster configuration:

```hcl
do_token             = "your_digitalocean_api_token"
tg_api_token         = "your_twingate_api_token"
tg_network           = "your_twingate_network" /* (https://{your_twingate_network}.twingate.com) */

clusters = {
  "tor-vpn-cluster" = {
    region     = "tor1"
    node_size  = "s-1vcpu-2gb"
    node_count = 1
  }
  "nyc-vpn-cluster" = {
    region     = "nyc1"
    node_size  = "s-2vcpu-4gb"
    node_count = 2
  }
  # Add more clusters as needed
}
```

### 2. Deploy Infrastructure

```bash
terraform init
terraform plan
terraform apply
```

The deployment process will:

1. Create the Twingate Exit Network
2. Deploy Kubernetes clusters in specified regions
3. Configure kubectl for each cluster
4. Deploy Twingate operator via Helm to each cluster
5. Create TwingateConnector resources in each cluster

### 3. Verify Deployment

After deployment, check the status:

```bash
# List all clusters
terraform output cluster_names

# Get kubeconfig commands for all clusters
terraform output kubeconfig_commands

# Check connector status in a specific cluster
doctl kubernetes cluster kubeconfig save tor-vpn-cluster
kubectl get twingateconnectors -n twingate
```

## Configuration Options

### Cluster Configuration

Each cluster in the `clusters` variable supports these options:

- `region` (required): DigitalOcean region code
- `node_size` (optional): Droplet size for nodes (default: "s-1vcpu-2gb")
- `node_count` (optional): Number of nodes (default: 1)

### Supported Regions

DigitalOcean supports clusters in these regions:

- `nyc1`, `nyc3` (New York)
- `ams3` (Amsterdam)
- `fra1` (Frankfurt)
- `tor1` (Toronto)
- `sgp1` (Singapore)
- `lon1` (London)
- `blr1` (Bangalore)
- `sfo3` (San Francisco)

## Adding a New Cluster

To add a new cluster, add an entry to the `clusters` variable in your `terraform.tfvars`:

```hcl
clusters = {
  # ... existing clusters ...
  "sfo-vpn-cluster" = {
    region     = "sfo3"
    node_size  = "s-1vcpu-2gb"
    node_count = 1
  }
}
```

Then run `terraform apply` to deploy the new cluster.

## Complete Shutdown

To completely shutdown the VPN infrastructure, run `terraform destroy`.

## Removing a Cluster

Remove the cluster entry from the `clusters` variable and run `terraform apply`. Terraform will destroy the cluster and its associated resources.

## File Structure

```bash
digital_ocean/
├── main.tf                    # Main cluster resources
├── deploy.tf                  # Deployment automation
├── variables.tf               # Input variables
├── outputs.tf                 # Output values
├── providers.tf               # Provider configurations
├── terraform.tfvars.example  # Example configuration
├── README.md                  # This file
└── modules/                   # Unused modules (for reference)
```

## Outputs

- `clusters`: Detailed information about all deployed clusters
- `cluster_names`: List of all cluster names
- `kubeconfig_commands`: Commands to configure kubectl for all clusters
- `twingate_remote_network_id`: The shared Twingate remote network ID
