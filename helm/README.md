# DIY VPN Helm Chart

A production-ready Helm chart for deploying Twingate to create Exit Networks in any Kubernetes cluster.

> **⚠️ Internal Use Only**: This project can only be used for personal or internal use. Please do not use this project or Twingate to offer a commercial VPN service. Also note that bandwidth usage through Twingate infrastructure is subject to Twingate's [Fair Use Policy](https://www.twingate.com/terms/sa).

## 🏗️ Overview

This Helm chart is designed as a standalone, reusable component that can be deployed to any Kubernetes cluster to create Twingate Exit Networks. It leverages the official Twingate Kubernetes operator to manage Connector lifecycle and provides enterprise-ready defaults.

```text
┌─────────────────────────────────┐
│       Kubernetes Cluster        │
│                                 │
│ ┌─────────────────────────────┐ │
│ │      twingate namespace     │ │
│ │                             │ │
│ │  ┌─────────────────────┐    │ │
│ │  │ Twingate Operator   │    │ │
│ │  │ (from OCI registry) │    │ │
│ │  └─────────────────────┘    │ │
│ │              │              │ │
│ │              ▼              │ │
│ │  ┌─────────────────────┐    │ │
│ │  │ TwingateConnector   │    │ │
│ │  │        (CRD)        │    │ │
│ │  └─────────────────────┘    │ │
│ │              │              │ │
│ │              ▼              │ │
│ │  ┌─────────────────────┐    │ │
│ │  │  Connector Pod(s)   │    │ │
│ │  │   (auto-managed)    │    │ │
│ │  └─────────────────────┘    │ │
│ └─────────────────────────────┘ │
└─────────────────────────────────┘
```

## ✨ Key Features

✅ **Universal Compatibility**: Works with any Kubernetes cluster (cloud or on-premises)
✅ **Official Integration**: Uses Twingate's official Kubernetes operator
✅ **Zero Configuration**: Sensible defaults with minimal required configuration
✅ **Highly Configurable**: Extensive customization options via Helm values
✅ **GitOps Friendly**: Declarative configuration suitable for CI/CD pipelines
✅ **Multi-Tenancy**: Support for namespace restrictions and RBAC

## 📋 Prerequisites

### Required Components

- **Kubernetes**: v1.19+ (tested up to v1.28)
- **Helm**: v3.8+
- **Network Access**: Cluster must reach Twingate cloud services (*.twingate.com)
- **Twingate Home** or other subscription plan that includes Exit Networks (not available on Starter plan)

### Required Credentials

- **Twingate Account**: Admin access to create API tokens
- **Twingate Network**: Your tenant name (e.g., `company.twingate.com` → `company`)
- **Twingate API Key**: Generated from Admin Console → Settings → API
- **Remote Network ID**: Created in Twingate Admin Console (or use existing)

## 🚀 Quick Start

### 1. Download and Configure

```bash
git clone https://github.com/Twingate-Community/diy-vpn.git
cd diy-vpn/helm
```

### 2. Update Dependencies

```bash
# Download the Twingate operator chart
helm dependency update
```

### 3. Configure Values

Create your `values.yaml` from the example:

```bash
cp values.example.yaml values.yaml
```

Edit `values.yaml` with your Twingate configuration:

```yaml
twingate-operator:
  twingateOperator:
    network: "your-company"                          # https://{network}.twingate.com
    apiKey: "your_twingate_api_key_here"             # https://{network}.twingate.com/settings/api
    remoteNetworkId: ""                              # https://{network}.twingate.com/exit-networks/{remoteNetworkId}
    logFormat: "json"                                 # Optional: json or text
    logVerbosity: "info"                             # Optional: debug, info, warn, error
```

### 4. Deploy

```bash
# Install to current cluster
helm install diy-vpn . \
  --namespace twingate \
  --create-namespace \
  --values values.yaml

# Or specify custom release name and namespace
helm install my-vpn-exit . \
  --namespace my-vpn \
  --create-namespace \
  --values values.yaml
```

### 5. Verify Deployment

```bash
# Check deployment status
helm status diy-vpn -n twingate

# Verify operator is running
kubectl get pods -n twingate

# Check connector resource
kubectl get twingateconnectors -n twingate

# View operator logs
kubectl logs -l app.kubernetes.io/name=twingate-operator -n twingate
```

## 🔧 Configuration Reference

### Required Configuration

| Parameter | Description | Example | Notes |
|-----------|-------------|---------|-------|
| `network` | Twingate tenant name | `"mycompany"` | From `mycompany.twingate.com` |
| `apiKey` | Twingate API token | `"wUsHFayeWt..."` | From Admin Console → Settings → API |
| `remoteNetworkId` | Exit network ID | `"UmVtb3RlT..."` | Select an Exit Network and copy the ID from the URL |

### Optional Configuration

| Parameter | Description | Default | Options |
|-----------|-------------|---------|---------|
| `logFormat` | Log output format | `"json"` | `"json"`, `"text"` |
| `logVerbosity` | Logging level | `"info"` | `"debug"`, `"info"`, `"warn"`, `"error"` |
| `namespaces` | Operator scope | `[]` (all) | Array of namespace patterns |

## 📦 Lifecycle Management

### Installation

```bash
# Standard installation
helm install diy-vpn . -f values.yaml -n twingate --create-namespace

# Installation with custom release name
helm install my-vpn-exit . -f values.yaml -n my-namespace --create-namespace

# Dry run to test configuration
helm install diy-vpn . -f values.yaml -n twingate --dry-run --debug
```

### Upgrades

```bash
# Update dependencies first
helm dependency update

# Upgrade existing release
helm upgrade diy-vpn . -f values.yaml -n twingate

# Upgrade with new values
helm upgrade diy-vpn . -f values-new.yaml -n twingate

# Rollback if needed
helm rollback diy-vpn 1 -n twingate
```

### Uninstallation

```bash
# Remove Helm release
helm uninstall diy-vpn -n twingate

# Clean up remaining resources (if needed)
kubectl delete twingateconnectors --all -n twingate
kubectl delete namespace twingate
```

## 🔍 Troubleshooting

### Common Issues & Solutions

| Issue | Symptoms | Solution |
|-------|----------|----------|
| **Operator CrashLoopBackOff** | Pod keeps restarting | Check API credentials, network connectivity |
| **Connector Not Created** | No TwingateConnector resource | Check operator logs, verify RBAC permissions |
| **Connector Offline** | Shows offline in Twingate Console | Check remote network ID, API token permissions |
| **High Resource Usage** | Pod using excessive CPU/memory | Adjust resource limits, check for memory leaks |
| **Image Pull Errors** | Can't pull operator image | Check network connectivity, image registry access |

### Getting Help

**Documentation Resources:**

- 📖 [Twingate Kubernetes Operator Docs](https://github.com/Twingate/kubernetes-operator)
- ⚙️ [Helm Documentation](https://helm.sh/docs/)
- ☸️ [Kubernetes Troubleshooting](https://kubernetes.io/docs/tasks/debug-application-cluster/)

**Community Support:**

- 💬 [Twingate Community Forum](https://reddit.com/r/twingate)
- 🐛 [Report Chart Issues](https://github.com/Twingate-Community/diy-vpn/issues)
- 📧 [Twingate Support](https://www.twingate.com/support)

---

🎉 **Success!** You now have a production-ready, reusable Helm chart for deploying Twingate Exit Networks to any Kubernetes cluster.