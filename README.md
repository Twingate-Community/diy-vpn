# DIY VPN - Twingate Exit Network Deployment

A comprehensive solution for deploying Twingate Exit Networks to create a DIY, globally-distributed VPN for personal use.

## 🚀 Overview

> **⚠️ Internal Use Only**: This project can only be used for personal or internal use. Please do not use this project or Twingate to offer a commercial VPN service. Also note that bandwidth usage is subject to Twingate's [Fair Use Policy](https://www.twingate.com/terms/sa).

This repository provides multiple deployment options for creating VPN Exit Networks with Twingate's zero-trust networking technology:

- **🧪 Minikube**: Local development and testing environment
- **🌊 DigitalOcean Droplets**: Small scale deployments
- **☸️ DigitalOcean Kubernetes**: Enterprise level implementation

> **⚠️ Important**: To access Exit Networks, you need a plan that includes Exit Networks, such as **Twingate Home** or **Twingate Enterprise**. Exit Networks are not available on the free Starter plan. [Learn more about Twingate plans](https://www.twingate.com/pricing).

## ✨ Key Features

✅ **Multi-Platform Support**: Deploy on droplets, Kubernetes clusters, or locally  
✅ **Zero-Trust Security**: No inbound ports open - all access is via Twingate  
✅ **Global Distribution**: Multi-region deployment capabilities

## 🏗️ Architecture

### Deployment Options

| Platform | Use Case | Cost |
|----------|----------|------|
| [Minikube](./minikube/) | Development, testing | 💰 Free |
| [DigitalOcean Droplets](./digital_ocean/droplet/) | Personal, cost-effective | 💰 Low |
| [DigitalOcean Kubernetes](./digital_ocean/kubernetes/) | Enterprise, auto-scaling | 💰💰 Medium |

> **💡 Choose One Option**: These are **separate, independent deployment methods** - not components that work together. Select the single option that best matches your specific needs and use case.

### Which Option Should I Choose?

#### 🧪 **Minikube** - Start Here

- **Perfect for**: Learning, development, testing configurations
- **Choose if**: You want to experiment locally before committing to cloud resources
- **Pros**: Free, fast iteration, safe testing environment. Can be used used as a free Exit Network
- **Cons**: Local only, not suitable for production traffic

#### 🌊 **DigitalOcean Droplets** - Most Popular

- **Perfect for**: Personal VPN, small teams, cost-conscious deployments
- **Choose if**: You want simple, reliable, cost-effective Exit Networks
- **Pros**: Lowest cost, simple architecture, production-ready
- **Cons**: Manual scaling, requires some Linux knowledge for troubleshooting

#### ☸️ **DigitalOcean Kubernetes** - Enterprise Grade

- **Perfect for**: Large organizations, auto-scaling requirements, complex deployments  
- **Choose if**: You need enterprise features and have Kubernetes expertise
- **Pros**: Auto-scaling, high availability, advanced orchestration
- **Cons**: Higher cost, complexity, requires Kubernetes knowledge

### Architecture Model

```text
┌─────────────────┐    ┌──────────────────┐    ┌─────────────────┐
│   User Device   │    │  Twingate Cloud  │    │   Exit Network  │
│                 │◄──►│                  │◄──►│                 │
│ Twingate Client │    │   Zero-Trust     │    │   Connector     │
└─────────────────┘    │   Controller     │    └─────────────────┘
                       └──────────────────┘
```

## 🚀 Quick Start

### Prerequisites

- [Terraform](https://www.terraform.io/downloads.html) >= 1.0
- **Twingate Home** or other subscription plan that includes Exit Networks (not available on Starter plan)
- Twingate account with API access
- Platform-specific requirements (see individual folders)

### 1. Choose Your Deployment Platform

**Select ONE option that fits your needs:**

| **Best for Beginners** | **Best for Production** | **Best for Development** |
|------------------------|-------------------------|-------------------------|
| [DigitalOcean Droplets](./digital_ocean/droplet/) | [DigitalOcean Kubernetes](./digital_ocean/kubernetes/) | [Minikube](./minikube/) |
| Simple, cost-effective | Auto-scaling, enterprise | Local testing |

> **Note**: These are independent deployment methods. Don't try to use multiple options together - pick the one that best matches your requirements.

### 2. Get Your Twingate Credentials

1. **API Token**: Twingate Admin Console → Settings → API
2. **Network Name**: Your tenant name (e.g., `company.twingate.com` → `company`)
3. **Exit Network ID**: Create an Exit Network in Twingate Admin Console

### 3. Deploy

Choose your platform and follow the detailed README in each folder:

```bash
# For Minikube (recommended for beginners / local development)
cd minikube
./deploy.sh

# For DigitalOcean Droplets (cost effective / personal use)
cd digital_ocean/droplet
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars with your credentials
terraform init
terraform apply

# For DigitalOcean Kubernetes (Enterprise)
cd digital_ocean/kubernetes
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars with your credentials
terraform init
terraform apply

```

## 📁 Repository Structure

```text
diy-vpn/
├── README.md                     # This file
├── digital_ocean/                # DigitalOcean deployments
│   ├── droplet/                  # Direct droplet deployment
│   │   ├── main.tf              # Core Terraform configuration
│   │   ├── variables.tf         # Input variables
│   │   ├── outputs.tf           # Output values
│   │   ├── terraform.tfvars.example
│   │   ├── templates/           # Cloud-init templates
│   │   └── README.md           # Detailed droplet guide
│   └── kubernetes/              # Kubernetes cluster deployment
│       ├── main.tf             # Cluster configuration
│       ├── deploy.tf           # Deployment automation
│       ├── variables.tf        # Input variables
│       ├── outputs.tf          # Output values
│       ├── terraform.tfvars.example
│       ├── config/             # Generated configurations
│       └── README.md          # Detailed Kubernetes guide
├── helm/                        # Reusable Helm chart
│   ├── Chart.yaml              # Chart metadata
│   ├── values.example.yaml     # Example configuration
│   ├── templates/              # Kubernetes templates
│   ├── charts/                 # Chart dependencies
│   └── README.md              # Helm chart documentation
└── minikube/                    # Local development
    ├── deploy.sh               # Deployment script
    ├── cleanup.sh              # Cleanup script
    ├── values.yaml             # Helm values
    ├── values-example.yaml     # Example configuration
    └── README.md              # Minikube guide
```

## 🌍 Global Deployment

**DigitalOcean Regions:**

- **North America**: NYC1, NYC2, NYC3, SFO1, SFO2, SFO3, TOR1
- **Europe**: AMS2, AMS3, LON1, FRA1
- **Asia Pacific**: SGP1, BLR1, SYD1

Current as of October 2025. Refer to [DigitalOcean](https://docs.digitalocean.com/platform/regional-availability/) for the most current list.

## 🛠️ Troubleshooting

### Common Issues

| Issue | Solution | Reference |
|-------|----------|-----------|
| Connector offline | Check API tokens and network connectivity | [Droplet README](./digital_ocean/droplet/README.md#troubleshooting) |
| Terraform state conflicts | Use separate state files per environment | [Kubernetes README](./digital_ocean/kubernetes/README.md#troubleshooting) |
| Helm deployment fails | Verify cluster connectivity and dependencies | [Helm README](./helm/README.md#troubleshooting) |
| Minikube issues | Check Docker and resource allocation | [Minikube README](./minikube/README.md#troubleshooting) |

### Support Resources

- 📖 [Twingate Documentation](https://docs.twingate.com/)
- 💬 [Twingate Community](https://www.reddit.com/r/twingate/)
- 🐛 [Report Issues](https://github.com/Twingate-Community/diy-vpn/issues)

### Development Workflow

1. Clone the repository
2. Create a feature branch
3. Test your changes locally with Minikube
4. Submit a pull request

## 📄 License

Copyright (C) Twingate Inc.

This project is licensed under the Server Side Public License v1 - see the [LICENSE](LICENSE) file for details.

---

**🚀 Ready to deploy your DIY VPN?** Choose your platform above and follow the detailed guides in each folder!
