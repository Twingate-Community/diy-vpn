# Multi-Cluster Twingate VPN Setup

This Terraform configuration deploys Twingate VPN connectors across multiple DigitalOcean Kubernetes clusters in different regions using a hybrid approach that combines Terraform resource management with deployment automation.

## Architecture

- **Multi-cluster deployment**: Deploy clusters across multiple DigitalOcean regions
- **Single Twingate Remote Network**: All connectors share the same exit network
- **Automated deployment**: Uses `null_resource` with local-exec to deploy Helm charts and connectors
- **Regional distribution**: Deploy clusters in any DigitalOcean region
- **Scalable**: Easy to add/remove clusters by modifying the `clusters` variable

## Prerequisites

- [Terraform](https://www.terraform.io/downloads.html) >= 1.0
- [doctl](https://docs.digitalocean.com/reference/doctl/how-to/install/) (DigitalOcean CLI)
- [kubectl](https://kubernetes.io/docs/tasks/tools/install-kubectl/)
- [helm](https://helm.sh/docs/intro/install/) >= 3.0
- DigitalOcean API token
- Twingate API token

## Usage

### 1. Configure Variables

Copy the example variables file and customize it:

```bash
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

1. Create the Twingate remote network
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

## Security Considerations

- API tokens are sensitive - use Terraform's sensitive variables
- Consider using remote state with encryption
- Network policies and RBAC are configured for security
- All containers run as non-root users
