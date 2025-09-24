# Multi-Region Twingate VPN on DigitalOcean Droplets

This Terraform configuration deploys Twingate VPN connectors across multiple DigitalOcean droplets in different regions using the official Twingate installation method. This provides a cost-effective, globally distributed VPN solution.

## Architecture

- **Multi-region deployment**: Deploy droplets across multiple DigitalOcean regions
- **Per-region exit networks**: Each region gets its own Twingate exit network (`do_{region}`)
- **Official Twingate installation**: Uses the official APT package and systemd service
- **Automated deployment**: Cloud-init handles complete connector setup
- **Security-first**: Locked-down firewall with minimal attack surface
- **Scalable**: Easy to add/remove regions and scale droplets per region

## Key Features

✅ **Cost-effective**: Uses small droplets (s-1vcpu-1gb) instead of Kubernetes overhead  
✅ **Official installation**: Uses Twingate's recommended APT package method  
✅ **Automatic updates**: Built-in security updates for system and Twingate packages  
✅ **High availability**: Multiple droplets per region support  
✅ **Zero-trust security**: No inbound ports open - all access via Twingate  
✅ **Production ready**: Systemd service management with proper restart policies  

## Prerequisites

- [Terraform](https://www.terraform.io/downloads.html) >= 1.0
- DigitalOcean API token
- Twingate API token
- Twingate Admin access to create connectors and networks

## Quick Start

### 1. Configure Variables

Copy the example variables file and customize it:

```bash
cp terraform.tfvars.example terraform.tfvars
```

Edit `terraform.tfvars` with your API tokens and desired droplet configuration:

```hcl
do_token     = "dop_v1_your_digitalocean_token"
tg_api_token = "your_twingate_api_token"
tg_network   = "your_twingate_network"

droplets = {
  "toronto-vpn" = {
    region = "tor1"
    size   = "s-1vcpu-1gb" 
    count  = 1
  }
  "newyork-vpn" = {
    region = "nyc1"
    size   = "s-1vcpu-1gb"
    count  = 1
  }
  # Add more regions as needed
}
```

### 2. Deploy Infrastructure

```bash
# Initialize Terraform
terraform init

# Review the deployment plan
terraform plan

# Deploy the infrastructure
terraform apply
```

### 3. Verify Deployment

After deployment, check the Twingate Admin Console to verify:

- Remote Networks created for each region (named `do_{region}`)
- Connectors online and connected to their respective networks
- Connectors properly labeled with region and deployment info

## Configuration Options

### Droplet Configuration

Each droplet configuration supports:

```hcl
"droplet-name" = {
  region = "tor1"                    # DigitalOcean region
  size   = "s-1vcpu-1gb"            # Droplet size
  count  = 1                        # Number of droplets in region
  image  = "ubuntu-24-04-x64"       # Operating system image
}
```

### Available Regions

Supported DigitalOcean regions:

- `nyc1`, `nyc2`, `nyc3` - New York
- `ams2`, `ams3` - Amsterdam  
- `sfo1`, `sfo2`, `sfo3` - San Francisco
- `sgp1` - Singapore
- `lon1` - London
- `fra1` - Frankfurt
- `tor1` - Toronto
- `blr1` - Bangalore
- `syd1` - Sydney

### Security Configuration

**Zero-Trust Security (Default):**

- No inbound ports open (complete lockdown)
- All outbound traffic allowed (required for Twingate connectivity)
- All server access happens through Twingate network
- Automatic security updates enabled

**SSH Keys (Optional - for emergency console access via DigitalOcean dashboard):**

```hcl
ssh_key_names = ["your-ssh-key-name"]  # Only for DigitalOcean console access
```

*Note: SSH keys don't open network ports - they're only for emergency console access via DigitalOcean's web interface.*

## Resource Naming

- **Droplets**:
  - Single droplet per region: `{region}-vpn` (e.g., `tor1-vpn`, `fra1-vpn`)
  - Multiple droplets per region: `{region}-vpn-{number}` (e.g., `ams3-vpn-01`, `ams3-vpn-02`)
- **Remote Networks**: `do_{region}` (e.g., `do_tor1`, `do_ams3`)  
- **Connectors**: Same as droplet names
- **Firewall**: `twingate-vpn-firewall` (shared across all droplets)

## Monitoring & Maintenance

### Service Status

Access droplets via Twingate network or DigitalOcean console:

```bash
systemctl status twingate-connector
journalctl -u twingate-connector -f  # View logs
```

### Automatic Updates

- System packages: Handled by `unattended-upgrades`
- Twingate packages: Included in automatic updates
- Restart policy: Service auto-restarts on failure

### Scaling Operations

**Add a new region:**

```hcl
droplets = {
  # ... existing droplets
  "london-vpn" = {
    region = "lon1"
    size   = "s-1vcpu-1gb"
    count  = 1
  }
}
```

**Scale existing region:**

```hcl
"toronto-vpn" = {
  region = "tor1"
  size   = "s-1vcpu-1gb"
  count  = 3  # Increased from 1
}
```

## Cost Optimization

- **Droplet size**: `s-1vcpu-1gb` sufficient for most VPN traffic (~$6/month)
- **Regional placement**: Choose regions close to your users
- **Scaling**: Start with 1 droplet per region, scale based on usage

## Troubleshooting

### Common Issues

**1. Connector not appearing online:**

- Check droplet status: `terraform output droplets`
- Verify cloud-init completed via DigitalOcean console or Twingate access
- Check connector service via console: `systemctl status twingate-connector`

**2. Invalid tokens:**

- Verify Twingate API token has correct permissions
- Check token expiry in Twingate Admin Console

**3. Droplet creation fails:**

- Verify DigitalOcean API token permissions  
- Check region availability and quotas
- Ensure SSH key exists if specified

### Logs and Debugging

Access via Twingate network or DigitalOcean console:

```bash
# Cloud-init logs
tail -f /var/log/cloud-init-output.log

# Twingate connector logs  
journalctl -u twingate-connector -f

# System logs
dmesg | tail
```

## Cleanup

To destroy all resources:

```bash
terraform destroy
```

This will remove:

- All droplets
- Twingate connectors and tokens
- Twingate remote networks  
- Firewall rules

## Security Considerations

- **Zero-trust network**: Firewall blocks ALL inbound traffic - no exceptions
- **Twingate-only access**: All server management happens through Twingate network
- **Token management**: Connector tokens stored securely in Terraform state
- **Automatic updates**: Prevents vulnerabilities through automated patching
- **Minimal attack surface**: No network services exposed, only Twingate connector
- **Console access**: Emergency access only via DigitalOcean web console (if SSH keys configured)
- **Monitoring**: Consider external monitoring for production deployments

## Support

For issues related to:

- **Terraform configuration**: Check this repository's issues
- **DigitalOcean**: Consult DigitalOcean documentation
- **Twingate**: Contact Twingate support or check documentation
