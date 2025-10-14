# DIY VPN on Minikube

Deploy and test locally using Minikube for development, testing, learning, and prototyping. This provides a complete local environment for experimenting with Twingate's zero-trust networking before deploying to production.

## 🏗️ Overview

```text
┌─────────────────────────────────┐
│      Local Development          │
│                                 │
│ ┌─────────────────────────────┐ │
│ │      Minikube Cluster       │ │
│ │                             │ │
│ │  ┌─────────────────────┐    │ │
│ │  │ Twingate Operator   │    │ │
│ │  │                     │    │ │
│ │  │ ┌─────────────────┐ │    │ │
│ │  │ │  Connector Pod  │ │    │ │
│ │  │ └─────────────────┘ │    │ │
│ │  └─────────────────────┘    │ │
│ └─────────────────────────────┘ │
└─────────────────────────────────┘
```

## ✨ Key Features

✅ **Zero Cost**: Completely free local development environment  
✅ **Quick Setup**: Automated deployment and cleanup scripts  
✅ **Full Feature Parity**: Same Twingate operator as production  
✅ **Easy Debugging**: Local access to all logs and configurations  
✅ **Safe Testing**: Isolated environment for experimentation  
✅ **Learning Friendly**: Perfect for understanding Twingate concepts  
✅ **CI/CD Testing**: Great for validating configurations in pipelines  
✅ **Rapid Iteration**: Quick destroy/redeploy cycles  

## 📋 Prerequisites

### Required Software

- **[Minikube](https://minikube.sigs.k8s.io/docs/start/)** >= 1.25.0
- **[kubectl](https://kubernetes.io/docs/tasks/tools/install-kubectl/)** >= 1.25.0
- **[Helm](https://helm.sh/docs/intro/install/)** >= 3.8.0
- **Container Runtime**: Docker Desktop, Podman, or containerd

### System Requirements

- **CPU**: 2+ cores (4+ recommended)
- **Memory**: 4GB+ RAM (8GB+ recommended)
- **Storage**: 10GB+ free disk space
- **Network**: Internet access for downloading images and connecting to Twingate

### Twingate Requirements

- **Twingate Home** or higher subscription plan (Exit Networks not available on Starter plan)
- **Twingate Account**: Admin access to create API tokens
- **API Token**: Generated from Twingate Admin Console
- **Remote Network**: Existing exit network or ability to create one

## 🚀 Quick Start

### 1. Install Prerequisites (macOS)

```bash
# Install via Homebrew
brew install minikube kubectl helm

# Or install individually
# Minikube: https://minikube.sigs.k8s.io/docs/start/
# kubectl: https://kubernetes.io/docs/tasks/tools/install-kubectl-macos/
# Helm: https://helm.sh/docs/intro/install/
```

### 2. Start Minikube

```bash
# Navigate to minikube directory
cd diy-vpn/minikube

# Start Minikube with optimal settings
minikube start --cpus=2 --memory=4096 --driver=docker

# Verify cluster is running
kubectl cluster-info
minikube status
```

### 3. Automated Deployment (Recommended)

The easiest way to get started is using the automated deployment script:

```bash
# Run the deployment script
./deploy.sh
```

This script will:

- ✅ Check prerequisites
- ✅ Start Minikube if not running
- ✅ Copy example values if needed
- ✅ Prompt you to edit configuration
- ✅ Deploy the Helm chart
- ✅ Show deployment status

### 4. Manual Deployment (Alternative)

If you prefer manual control:

```bash
# Copy and edit configuration
cp values-example.yaml values.yaml
# Edit values.yaml with your Twingate credentials

# Update Helm dependencies
cd ../helm
helm dependency update

# Deploy to Minikube
helm install diy-vpn-local . \
  -f ../minikube/values.yaml \
  --namespace twingate \
  --create-namespace \
  --wait \
  --timeout 5m

# Verify deployment
kubectl get pods -n twingate
kubectl get twingateconnectors -n twingate
```

## 🔧 Configuration Guide

### Basic Configuration

Edit `values.yaml` with your Twingate credentials:

```yaml
twingate-operator:
  twingateOperator:
    network: "your-company"                          # https://{network}.twingate.com
    apiKey: "your_twingate_api_key_here"             # https://{network}.twingate.com/settings/api
    remoteNetworkId: ""                              # https://{network}.twingate.com/exit-networks/{remoteNetworkId}
    logFormat: "json"
    logVerbosity: "debug"                            # Helpful for local development
```

### Resource-Optimized Configuration

For systems with limited resources:

```yaml
twingate-operator:
  twingateOperator:
    network: "your-company"
    apiKey: "your_api_key"
    remoteNetworkId: "your_network_id"
    logVerbosity: "info"  # Less verbose logging
    
  # Minimal resource requirements
  resources:
    requests:
      cpu: 50m
      memory: 64Mi
    limits:
      cpu: 200m
      memory: 256Mi
```

### Development Configuration

For active development and debugging:

```yaml
twingate-operator:
  twingateOperator:
    network: "your-company-dev"
    apiKey: "dev_api_key"
    remoteNetworkId: "dev_network_id"
    logVerbosity: "debug"
    
  # Higher resources for development
  resources:
    requests:
      cpu: 100m
      memory: 128Mi
    limits:
      cpu: 500m
      memory: 512Mi
```

## 🔄 Development Workflows

### Standard Development Cycle

```bash
# 1. Make configuration changes
vim values.yaml

# 2. Update deployment
helm upgrade diy-vpn-local ../helm \
  -f values.yaml \
  -n twingate

# 3. Watch deployment progress
kubectl get pods -n twingate -w

# 4. Check logs
kubectl logs -f -l app.kubernetes.io/name=twingate-operator -n twingate
```

### Testing Different Configurations

```bash
# Deploy multiple configurations for comparison
helm install vpn-config-a ../helm -f values-config-a.yaml -n twingate-a --create-namespace
helm install vpn-config-b ../helm -f values-config-b.yaml -n twingate-b --create-namespace

# Compare results
kubectl get twingateconnectors -A
```

### Quick Reset and Redeploy

```bash
# Use the cleanup script
./cleanup.sh

# Redeploy with new configuration
./deploy.sh
```

## 🔍 Monitoring & Debugging

### Health Checks

```bash
# Check overall deployment health
kubectl get all -n twingate

# Check specific resources
kubectl get deployment,pod,twingateconnector -n twingate

# Check node resources
kubectl describe nodes
```

### Detailed Diagnostics

```bash
# Operator deployment details
kubectl describe deployment -n twingate

# Pod details
kubectl describe pods -n twingate

# Connector resource details
kubectl describe twingateconnector -n twingate

# Recent events
kubectl get events -n twingate --sort-by=.metadata.creationTimestamp
```

### Log Analysis

```bash
# Real-time operator logs
kubectl logs -f -l app.kubernetes.io/name=twingate-operator -n twingate

# Historical logs with timestamps
kubectl logs -l app.kubernetes.io/name=twingate-operator -n twingate --timestamps

# All container logs in namespace
kubectl logs --all-containers=true -n twingate
```

### Performance Monitoring

```bash
# Enable metrics server (if not already enabled)
minikube addons enable metrics-server

# Check resource usage
kubectl top nodes
kubectl top pods -n twingate

# Check cluster resource allocation
kubectl describe nodes | grep -A 5 "Allocated resources"
```

## 🔍 Troubleshooting Guide

### Common Issues & Solutions

| Issue | Symptoms | Solution |
|-------|----------|----------|
| **Minikube won't start** | Error during minikube start | `minikube delete && minikube start --driver=docker --force` |
| **Insufficient resources** | Pods stuck in Pending | Increase Minikube resources or reduce pod resource requests |
| **Operator CrashLoopBackOff** | Pod keeps restarting | Check API credentials, view logs with `kubectl logs` |
| **Connector not appearing** | No connector in Twingate Console | Verify API token permissions, check remote network ID |
| **DNS resolution issues** | Network timeouts | Check Minikube DNS: `minikube addons enable dns` |
| **Image pull errors** | Can't download images | Check internet connection, try `minikube ssh docker pull <image>` |

## 📞 Support & Resources

### Documentation

- 📖 [Minikube Official Docs](https://minikube.sigs.k8s.io/docs/)
- ☸️ [Kubernetes Documentation](https://kubernetes.io/docs/)
- ⚙️ [Helm Documentation](https://helm.sh/docs/)
- 🔒 [Twingate Kubernetes Operator](https://github.com/Twingate/kubernetes-operator)

### Community Support

- 💬 [Twingate Community Forum](https://reddit.com/r/twingate)
- 🐛 [Report Issues](https://github.com/Twingate-Community/diy-vpn/issues)

---

🎉 **Congratulations!** You now have a fully functional local development environment for testing and learning Twingate's zero-trust networking. Ready to move to production? Check out our [DigitalOcean deployment options](../digital_ocean/)!
