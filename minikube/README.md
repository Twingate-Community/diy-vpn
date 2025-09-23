# DIY VPN on Minikube

Deploy Twingate VPN connectors locally using Minikube for development, testing, or local exit networking.

## Overview

This setup allows you to deploy the DIY VPN solution on a local Minikube cluster. It's perfect for:

- **Development and testing** of VPN configurations
- **Local exit networking** for development environments
- **Learning** Twingate and Kubernetes concepts
- **Prototyping** before cloud deployment

## Prerequisites

- [Minikube](https://minikube.sigs.k8s.io/docs/start/) installed
- [kubectl](https://kubernetes.io/docs/tasks/tools/install-kubectl/) configured
- [Helm](https://helm.sh/docs/intro/install/) 3.0+
- Twingate account with API access
- Docker Desktop or compatible container runtime

## Quick Start

### 1. Start Minikube

```bash
# Start Minikube with sufficient resources
minikube start --cpus=2 --memory=4096 --driver=docker

# Verify cluster is running
kubectl cluster-info
```

### 2. Configure Twingate Values

Copy the example values file and customize it:

```bash
cp values-example.yaml values.yaml
```

Edit `values.yaml` with your Twingate credentials:

```yaml
twingate-operator:
  twingateOperator:
    network: "your-tenant-name"
    apiKey: "your-twingate-api-key"
    # Optional: specify existing remote network
    # remoteNetworkId: "your-remote-network-id"
```

### 3. Deploy with Helm

```bash
# Add and update Helm dependencies
cd ../helm
helm dependency update

# Deploy to Minikube
helm install diy-vpn-local . \
  -f ../minikube/values.yaml \
  --namespace twingate \
  --create-namespace
```

### 4. Verify Deployment

```bash
# Check operator status
kubectl get pods -n twingate

# Check connector status
kubectl get twingateconnectors -n twingate

# View logs
kubectl logs -l app.kubernetes.io/name=twingate-operator -n twingate -f
```

## Configuration Options

### Resource-Constrained Setup

For systems with limited resources, use the minimal configuration:

```bash
cp values-minimal.yaml values.yaml
```

### Development with Hot-Reload

Enable development mode with faster reconciliation:

```yaml
twingate-operator:
  twingateOperator:
    logVerbosity: "debug"
    # Add development-specific settings
  resources:
    requests:
      cpu: 50m
      memory: 64Mi
    limits:
      cpu: 200m
      memory: 256Mi
```

## Local Networking

### Port Forwarding for Testing

To test connectivity through your local VPN connector:

```bash
# Forward connector metrics (if available)
kubectl port-forward -n twingate service/diy-vpn-local-twingate-operator 8080:8080

# Access metrics at http://localhost:8080/metrics
```

### LoadBalancer Services

Minikube supports LoadBalancer services via tunnel:

```bash
# Enable LoadBalancer access (run in separate terminal)
minikube tunnel

# Check external IPs
kubectl get services -n twingate
```

## Development Workflow

### 1. Code and Test Cycle

```bash
# Make changes to values then apply
helm upgrade diy-vpn-local ../helm \
  -f values.yaml \
  -n twingate

# Check status
kubectl get pods -n twingate -w
```

### 2. Debug Issues

```bash
# Describe resources
kubectl describe twingateconnector -n twingate
kubectl describe pods -n twingate

# Check events
kubectl get events -n twingate --sort-by=.metadata.creationTimestamp

# Operator logs
kubectl logs -l app.kubernetes.io/name=twingate-operator -n twingate --tail=100
```

### 3. Reset Environment

```bash
# Uninstall chart
helm uninstall diy-vpn-local -n twingate

# Clean up namespace
kubectl delete namespace twingate

# Restart Minikube if needed
minikube stop && minikube start
```

## Advanced Usage

### Multiple Connectors

Deploy multiple connectors for testing different configurations:

```bash
# Deploy second connector with different name
helm install diy-vpn-test ../helm \
  -f values-test.yaml \
  --namespace twingate-test \
  --create-namespace
```

### Persistent Development

For persistent development across Minikube restarts:

```bash
# Start with persistent storage
minikube start --cpus=2 --memory=4096 --mount --mount-string="$HOME/twingate-data:/data"
```

### Resource Monitoring

Monitor resource usage during development:

```bash
# Enable metrics server
minikube addons enable metrics-server

# Check resource usage
kubectl top pods -n twingate
kubectl top nodes
```

## Troubleshooting

### Common Issues

1. **Minikube won't start**

   ```bash
   minikube delete
   minikube start --driver=docker --force
   ```

2. **Insufficient resources**

   ```bash
   minikube config set cpus 2
   minikube config set memory 4096
   minikube delete && minikube start
   ```

3. **Pod stuck in Pending**

   ```bash
   kubectl describe pod <pod-name> -n twingate
   # Usually indicates resource constraints
   ```

4. **Connector not appearing in Twingate**
   - Verify API key has correct permissions
   - Check network name matches tenant
   - Review operator logs for authentication errors

### Getting Logs

```bash
# All logs from twingate namespace
kubectl logs --all-containers=true -n twingate

# Specific operator logs
kubectl logs deployment/diy-vpn-local-twingate-operator -n twingate

# Follow logs in real-time
kubectl logs -f -l app.kubernetes.io/name=twingate-operator -n twingate
```

## Performance Considerations

### Resource Allocation

Recommended Minikube settings for smooth operation:

```bash
# Minimum for basic testing
minikube start --cpus=2 --memory=2048

# Recommended for development
minikube start --cpus=4 --memory=4096

# For multiple connectors or heavy testing
minikube start --cpus=4 --memory=8192
```

### Storage

Enable persistent storage for connector state:

```bash
minikube addons enable default-storageclass
minikube addons enable storage-provisioner
```

## Integration with Cloud

### Hybrid Setup

Use Minikube for development while testing against cloud remote networks:

1. Create remote network in cloud (DigitalOcean setup)
2. Use the same remote network ID in Minikube
3. Test traffic routing between local and cloud connectors

### Migration Path

When ready to move to production:

1. Export working configuration from Minikube
2. Apply same values to cloud deployment
3. Update DNS/routing as needed

## Files in this Directory

- `README.md` - This documentation
- `values-example.yaml` - Example configuration
- `values-minimal.yaml` - Minimal resource configuration
- `deploy.sh` - Quick deployment script
- `cleanup.sh` - Environment cleanup script

## Next Steps

Once you have a working local setup:

1. **Scale to cloud**: Use the `../digital_ocean/` setup for production
2. **Customize networking**: Modify connector configurations for specific use cases
3. **Automate deployment**: Create CI/CD pipelines using the patterns established here

## Support

- [Minikube Documentation](https://minikube.sigs.k8s.io/docs/)
- [Twingate Kubernetes Operator](https://github.com/Twingate/kubernetes-operator)
- [Helm Documentation](https://helm.sh/docs/)
