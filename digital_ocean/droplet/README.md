# Multi-Region Twingate VPN on DigitalOcean Droplets

Deploy cost-effective, globally distributed Twingate VPN Connectors across multiple DigitalOcean droplets using the official Twingate installation method. This provides the most economical way to create Exit Networks with enterprise-grade security.

> **⚠️ Internal Use Only**: This project can only be used for personal or internal use. Please do not use this project or Twingate to offer a commercial VPN service. Also note that bandwidth usage through Twingate infrastructure is subject to Twingate's [Fair Use Policy](https://www.twingate.com/terms/sa).

## 🏗️ Architecture

```text
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   NYC1 Region   │    │   AMS3 Region   │    │   SGP1 Region   │
│                 │    │                 │    │                 │
│ ┌─────────────┐ │    │ ┌─────────────┐ │    │ ┌─────────────┐ │
│ │   Droplet   │ │    │ │   Droplet   │ │    │ │   Droplet   │ │
│ │ nyc1-vpn-01 │ │    │ │ ams3-vpn-01 │ │    │ │ sgp1-vpn-01 │ │
│ │             │ │    │ │             │ │    │ │             │ │
│ │ Twingate    │ │    │ │ Twingate    │ │    │ │ Twingate    │ │
│ │ Connector   │ │    │ │ Connector   │ │    │ │ Connector   │ │
│ └─────────────┘ │    │ └─────────────┘ │    │ └─────────────┘ │
└─────────────────┘    └─────────────────┘    └─────────────────┘
         │                       │                       │
         └───────────────────────┼───────────────────────┘
                                 │
                    ┌─────────────────────┐
                    │  Twingate Cloud     │
                    │  do_nyc1 Network    │
                    │  do_ams3 Network    │
                    │  do_sgp1 Network    │
                    └─────────────────────┘
```

### Key Design Principles

- **Per-Region Exit Networks**: Each region gets its own Twingate remote network (`do_{region}`)
- **Zero-Trust Security**: Completely locked-down firewall with no inbound ports
- **Official Installation**: Uses Twingate's recommended APT package and systemd service
- **Cloud-Init Automation**: Complete Connector setup without manual intervention
- **Cost Optimization**: Uses minimal droplet sizes (s-1vcpu-1gb) for maximum cost effectiveness
- **High Availability**: Support for multiple droplets per region

## ✨ Key Features

✅ **Official Integration**: Uses Twingate's recommended APT package installation
✅ **Zero-Trust Security**: No SSH, no inbound ports - access only via Twingate
✅ **Automatic Updates**: Built-in security updates for system and Twingate packages  
✅ **Production Ready**: Systemd service management with restart policies and logging  
✅ **Multi-Region Support**: Deploy across any DigitalOcean region
✅ **Scalable**: Easy to add/remove regions and scale droplets per region
✅ **Infrastructure as Code**: Complete Terraform automation with proper state management  

## 📋 Prerequisites

### Required Tools

- [Terraform](https://www.terraform.io/downloads.html) >= 1.0
- DigitalOcean account with API access
- **Twingate Home** or other subscription plan that includes Exit Networks (not available on Starter plan)
- Twingate account with Admin privileges

### Required Credentials

- **DigitalOcean API Token**: Generate from [DigitalOcean Control Panel](https://cloud.digitalocean.com/account/api/tokens)
- **Twingate Account**: Admin access to create API tokens
- **Twingate API Token**: Generate from Twingate Admin Console → Settings → API
- **Twingate Network Name**: Your tenant name (e.g., `company.twingate.com` → `company`)

### Optional (for debugging)

- SSH key configured in DigitalOcean (not recommended for production)

## 🚀 Quick Start

### 1. Clone and Configure

```bash
# Clone the repository
git clone https://github.com/Twingate-Community/diy-vpn.git
cd diy-vpn/digital_ocean/droplet

# Copy the example configuration
cp terraform.tfvars.example terraform.tfvars
```

### 2. Edit Configuration

Edit `terraform.tfvars` with your credentials and desired droplet configuration:

```hcl
# Required: API credentials
do_token     = "dop_v1_your_digitalocean_api_token_here"
tg_api_token = "your_twingate_api_token_here"
tg_network   = "your_twingate_network_name"

# Configure droplets across regions
droplets = {
  "toronto-vpn" = {
    region = "tor1"
    size   = "s-1vcpu-1gb"
    count  = 1
    image  = "ubuntu-24-04-x64"
  }
  "newyork-vpn" = {
    region = "nyc1" 
    size   = "s-1vcpu-1gb"
    count  = 1
    image  = "ubuntu-24-04-x64"
  }
  "amsterdam-vpn" = {
    region = "ams3"
    size   = "s-1vcpu-1gb"
    count  = 2  # Multiple droplets for HA
    image  = "ubuntu-24-04-x64"
  }
}

# Optional: SSH keys for emergency console access only
ssh_key_names = []  # Leave empty for maximum security

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

1. **Remote Networks**: Should see networks like `do_tor1`, `do_nyc1`, `do_ams3`
2. **Connectors**: Should show online Connectors for each droplet
3. **Labels**: Connectors properly labeled with region, deployment method, and environment

**Expected Output Example:**

```text
deployment_summary = {
  "connectors" = 4
  "environment" = "production"
  "remote_networks" = 3
  "total_droplets" = 4
  "twingate_network" = "yourcompany"
  "unique_regions" = 3
}
```

## Complete Shutdown

To completely shutdown the VPN infrastructure, run `terraform destroy`.

## 🔧 Configuration Reference

### Droplet Configuration Options

Each droplet entry in the `droplets` map supports these parameters:

```hcl
"droplet-name" = {
  region = "tor1"                   # Required: DigitalOcean region
  size   = "s-1vcpu-1gb"            # Optional: Droplet size (default: s-1vcpu-1gb)
  count  = 1                        # Optional: Number of droplets (default: 1)
  image  = "ubuntu-24-04-x64"       # Optional: OS image (default: ubuntu-24-04-x64)
}
```

### Supported DigitalOcean Regions

| Region | Location | Code | Typical Use Case |
|--------|----------|------|------------------|
| **North America** | | | |
| New York | USA East | `nyc1`, `nyc2`, `nyc3` | East Coast users |
| San Francisco | USA West | `sfo1`, `sfo2`, `sfo3` | West Coast users |
| Toronto | Canada | `tor1` | Canadian users |
| **Europe** | | | |
| Amsterdam | Netherlands | `ams2`, `ams3` | European users |
| London | UK | `lon1` | UK/Ireland users |
| Frankfurt | Germany | `fra1` | Central Europe |
| **Asia Pacific** | | | |
| Singapore | Singapore | `sgp1` | Southeast Asia |
| Bangalore | India | `blr1` | India/South Asia |
| Sydney | Australia | `syd1` | Australia/Oceania |

### Droplet Sizes

| Size | vCPUs | Memory | Storage | Transfer | Recommended For |
|------|-------|--------|---------|----------|-----------------|
| `s-1vcpu-1gb` | 1 | 1GB | 25GB SSD | 1TB | **Recommended**: Most VPN traffic |
| `s-1vcpu-2gb` | 1 | 2GB | 50GB SSD | 2TB | High traffic or multiple users |
| `s-2vcpu-2gb` | 2 | 2GB | 60GB SSD | 3TB | Very high traffic |

> **💡 Cost Tip**: Start with `s-1vcpu-1gb` - it handles most VPN workloads efficiently.

Details current as of October 2025. Refer to [DigitalOcean](https://www.digitalocean.com/pricing) for the most current details.

### Security Configuration

**Zero-Trust Security (Default - recommended):**

```hcl
# Maximum security - no direct access
ssh_key_names = []                 # No SSH keys
environment   = "production"       # Production security settings
```

**Emergency Access (Optional - for debugging only):**

```hcl
# Emergency console access via DigitalOcean dashboard only
ssh_key_names = ["your-key-name"]  # SSH key for console access
environment   = "development"       # Development settings
```

> **⚠️ Security Note**: SSH keys only provide console access via DigitalOcean's web interface. Network SSH is completely blocked.

## 📋 Resource Management

### Naming Conventions

| Resource Type | Naming Pattern | Examples |
|--------------|----------------|----------|
| **Single Droplet** | `{region}-vpn` | `tor1-vpn`, `fra1-vpn` |
| **Multiple Droplets** | `{region}-vpn-{nn}` | `ams3-vpn-01`, `ams3-vpn-02` |
| **Remote Networks** | `do_{region}` | `do_tor1`, `do_ams3` |
| **Connectors** | Same as droplet | `tor1-vpn`, `ams3-vpn-01` |
| **Firewall** | `twingate-vpn-firewall` | Shared across all droplets |

### Tags Applied to All Resources

- `twingate-vpn` - Identifies VPN infrastructure
- `region-{region}` - Regional grouping
- `env-{environment}` - Environment designation

## 🔧 Operations & Maintenance

### Health Monitoring

**Via Terraform Outputs:**

```bash
# Check deployment status
terraform output deployment_summary

# Get droplet information
terraform output droplets

# View remote networks
terraform output twingate_remote_networks
```

**Via Twingate Admin Console:**

1. Navigate to "Networks" → Check Connector status (should be green/online)
2. Navigate to "Analytics" → Monitor Connector traffic and health
3. Check Connector labels for deployment metadata

**Via DigitalOcean Console (if needed):**

1. Droplets → View droplet status and resource usage
2. Networking → Firewall rules verification
3. Console access for emergency debugging

### Service Management

Access droplets via Twingate network or DigitalOcean console:

```bash
# Check Connector service status
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
droplets = {
  # ... existing droplets ...
  "singapore-vpn" = {
    region = "sgp1"
    size   = "s-1vcpu-1gb"
    count  = 1
    image  = "ubuntu-24-04-x64"
  }
}
```

**Scaling Existing Region (High Availability):**

```hcl
"amsterdam-vpn" = {
  region = "ams3"
  size   = "s-1vcpu-1gb"
  count  = 3  # Increased from 1 for HA
  image  = "ubuntu-24-04-x64"
}
```

**Upgrading Droplet Size:**

```hcl
"toronto-vpn" = {
  region = "tor1"
  size   = "s-1vcpu-2gb"  # Upgraded from s-1vcpu-1gb
  count  = 1
  image  = "ubuntu-24-04-x64"
}
```

> **⚠️ Note**: Changing droplet size requires recreation (brief downtime)

## 🔍 Troubleshooting

### Common Issues & Solutions

| Issue | Symptoms | Solution |
|-------|----------|----------|
| **Connector Offline** | Connector shows offline in Twingate Console | Check cloud-init logs, verify tokens, restart service |
| **Droplet Creation Fails** | Terraform apply fails during droplet creation | Check API token permissions, region availability, quotas |
| **Invalid API Tokens** | Authentication errors in logs | Verify tokens in respective admin consoles, check expiry |
| **High Resource Usage** | Droplet performance issues | Monitor with `htop`, consider upgrading droplet size |
| **Network Connectivity Issues** | Slow or failed connections | Check regional latency, consider adding more regions |

### Diagnostic Commands

**Via Twingate Network or DigitalOcean Console:**

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
sudo cat /etc/twingate/connector.conf  # Configuration file
```

**Via Terraform:**

```bash
# Check deployment status
terraform output deployment_summary
terraform output droplets

# Validate configuration
terraform validate
terraform plan

# Refresh state and check for drift
terraform refresh
```

### Performance Tuning

**For High Traffic Scenarios:**

1. **Upgrade Droplet Size**:

   ```hcl
   size = "s-1vcpu-2gb"  # or "s-2vcpu-2gb"
   ```

2. **Add Multiple Droplets per Region**:

   ```hcl
   count = 2  # or more for load distribution
   ```

3. **Monitor with Twingate Analytics**: Check Connector load and distribute users

### Emergency Procedures

**If Connector Goes Offline:**

1. Check Twingate Admin Console for Connector status
2. Access via DigitalOcean console (if SSH keys configured)
3. Restart Connector service: `sudo systemctl restart twingate-connector`
4. If persistent, recreate droplet: `terraform taint digitalocean_droplet.twingate_connectors["droplet-name"]`

**Complete Recovery:**

```bash
# Destroy and recreate specific droplet
terraform destroy -target="digitalocean_droplet.twingate_connectors[\"tor1-vpn\"]"
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
droplets = {
  # "toronto-vpn" = {  # Commented out
  #   region = "tor1"
  #   size   = "s-1vcpu-1gb"
  #   count  = 1
  # }
  "newyork-vpn" = {
    region = "nyc1"
    size   = "s-1vcpu-1gb"
    count  = 1
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

- ✅ DigitalOcean droplets
- ✅ DigitalOcean firewall rules
- ✅ Twingate remote networks
- ✅ Twingate Connectors
- ✅ Twingate Connector tokens

## 🔒 Security Best Practices

### Production Security Checklist

- [ ] **No SSH Keys**: Use `ssh_key_names = []` for maximum security
- [ ] **Token Rotation**: Regularly rotate Twingate API tokens
- [ ] **State File Security**: Secure Terraform state file (contains sensitive tokens)
- [ ] **Network Monitoring**: Monitor Twingate Analytics for unusual activity
- [ ] **Update Management**: Verify automatic updates are working
- [ ] **Backup Strategy**: Document recovery procedures

### Advanced Security Configuration

**State File Encryption:**

```bash
# Use remote state with encryption
terraform {
  backend "s3" {
    bucket  = "your-terraform-state"
    key     = "twingate-vpn/terraform.tfstate"
    region  = "us-east-1"
    encrypt = true
  }
}
```

**Token Management:**

```bash
# Use environment variables instead of tfvars for CI/CD
export TF_VAR_do_token="your_do_token"
export TF_VAR_tg_api_token="your_tg_token"
```

## 📞 Support & Resources

### Documentation Links

- 📖 [Twingate Connector Documentation](https://docs.twingate.com/docs/connector-deployment-guides)
- 🌊 [DigitalOcean API Documentation](https://docs.digitalocean.com/reference/api/)
- 🏗️ [Terraform DigitalOcean Provider](https://registry.terraform.io/providers/digitalocean/digitalocean/latest/docs)

### Community Support

- 💬 [Twingate Community Forum](https://community.twingate.com/)
- 🐛 [Report Issues](https://github.com/Twingate-Community/diy-vpn/issues)
- 📧 [Twingate Support](https://www.twingate.com/support)

### Getting Help

**For Infrastructure Issues:**

1. Check troubleshooting section above
2. Review Terraform logs: `terraform apply -auto-approve -no-color 2>&1 | tee terraform.log`
3. Post logs in GitHub issues (remove sensitive tokens)

**For Twingate Issues:**

1. Check Twingate Admin Console logs
2. Review Connector service logs
3. Contact Twingate support with Connector IDs

---

🎉 **Congratulations!** You now have a production-ready, cost-effective, globally distributed VPN infrastructure powered by Twingate's zero-trust networking.
