# DIY VPN Helm Chart

A Helm chart for deploying Twingate VPN connectors to create exit networks in Kubernetes clusters. This chart simplifies the deployment of Twingate's zero-trust networking solution for creating VPN exit points.

## Overview

This Helm chart deploys the Twingate Kubernetes operator and creates a TwingateConnector resource that establishes an exit network connection. It's designed for creating VPN exit nodes that allow traffic to egress through specific geographic regions or network locations.

## Prerequisites

- Kubernetes cluster (v1.19+)
- Helm 3.0+
- Twingate account with API access
- `kubectl` configured to access your cluster

## Installation

### 1. Add Dependencies

First, update the chart dependencies to download the Twingate operator:

```bash
helm dependency update
```

### 2. Configure Values

Create a `values.yaml` by copying `values.example.yaml` and fill in your Twingate configuration:

```yaml
twingate-operator:
  twingateOperator:
    network: "your-tenant-name"           # Your Twingate tenant name
    apiKey: "your-twingate-api-key"       # Twingate API key
    remoteNetworkId: "your-network-id"    # Exit Network ID
    logFormat: "json"
    logVerbosity: "debug"
```

### 3. Deploy the Chart

```bash
# Install in the default namespace
helm install diy-vpn . -f values-custom.yaml

# Or install in a specific namespace
helm install diy-vpn . -f values-custom.yaml --namespace twingate --create-namespace
```

## Configuration

### Required Values

| Parameter | Description | Required |
|-----------|-------------|----------|
| `twingate-operator.twingateOperator.network` | Your Twingate tenant name | ✅ |
| `twingate-operator.twingateOperator.apiKey` | Twingate API token | ✅ |
| `twingate-operator.twingateOperator.remoteNetworkId` | Existing Exit Network ID | ✅ |

### Optional Values

| Parameter | Description | Default |
|-----------|-------------|---------|
| `twingate-operator.twingateOperator.logFormat` | Log format (json/text) | `"json"` |
| `twingate-operator.twingateOperator.logVerbosity` | Log verbosity level | `"debug"` |

### Security Configuration

The chart includes secure defaults:

```yaml
twingate-operator:
  podSecurityContext:
    seccompProfile:
      type: RuntimeDefault

  securityContext:
    capabilities:
      drop: ["ALL"]
    readOnlyRootFilesystem: true
    runAsNonRoot: true
    allowPrivilegeEscalation: false
    runAsUser: 1000
```

### TwingateConnector Configuration

The chart creates a TwingateConnector resource with automatic image updates:

```yaml
apiVersion: twingate.com/v1beta
kind: TwingateConnector
metadata:
  name: vpn-node
spec:
  imagePolicy:
    provider: dockerhub
    schedule: "0 0 * * *"  # Daily updates at midnight
```

## Verification

After installation, verify the deployment:

```bash
# Check operator deployment
kubectl get deployments -l app.kubernetes.io/name=twingate-operator

# Check connector status
kubectl get twingateconnectors

# View operator logs
kubectl logs -l app.kubernetes.io/name=twingate-operator -f
```

## Upgrading

To upgrade the chart:

```bash
# Update dependencies
helm dependency update

# Upgrade the release
helm upgrade diy-vpn . -f values-custom.yaml
```

## Uninstalling

To remove the chart:

```bash
helm uninstall diy-vpn
```

**Note**: This will remove the operator but TwingateConnector resources may need manual cleanup.

## Troubleshooting

### Common Issues

1. **Operator not starting**

   ```bash
   kubectl describe deployment -l app.kubernetes.io/name=twingate-operator
   kubectl logs -l app.kubernetes.io/name=twingate-operator
   ```

2. **Connector not connecting**

   ```bash
   kubectl describe twingateconnector vpn-node
   kubectl get events --sort-by=.metadata.creationTimestamp
   ```

3. **API authentication issues**
   - Verify your Twingate API token has the correct permissions
   - Check that the network name matches your Twingate tenant

### Getting Support

- [Twingate Documentation](https://docs.twingate.com/)
- [Kubernetes Operator GitHub](https://github.com/Twingate/kubernetes-operator)
- [Twingate Community](https://community.twingate.com/)

## License

This chart is part of the DIY VPN project and follows the same license terms.
