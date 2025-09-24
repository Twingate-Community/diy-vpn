# Multi-Cluster Deployment Script
# This script handles the deployment of Twingate operators to multiple clusters

locals {
  # Create helm values for each cluster with cluster-specific remote network
  helm_values_per_cluster = {
    for cluster_key, cluster_config in var.clusters : cluster_key => yamlencode({
      twingateOperator = {
        network         = var.tg_network
        apiKey          = var.tg_api_token
        remoteNetworkId = twingate_remote_network.vpn_networks[cluster_key].id
        logFormat       = "json"
        logVerbosity    = "debug"
      }

      podSecurityContext = {
        seccompProfile = {
          type = "RuntimeDefault"
        }
      }

      securityContext = {
        capabilities = {
          drop = ["ALL"]
        }
        readOnlyRootFilesystem   = true
        runAsNonRoot             = true
        allowPrivilegeEscalation = false
        runAsUser                = 1000
      }

      "kubernetes-access-gateway" = {
        enabled = false
      }

      image = {
        repository = "twingate/kubernetes-operator"
        pullPolicy = "IfNotPresent"
        tag        = ""
      }

      serviceAccount = {
        create      = true
        annotations = {}
        name        = ""
      }

      affinity       = {}
      nodeSelector   = {}
      podAnnotations = {}
      podLabels      = {}
      resources      = {}
      rbac = {
        createAggregateClusterRoles = false
      }
      priorityClassName = ""
      nameOverride      = ""
      fullnameOverride  = ""
      extraEnvVars      = []
      imagePullSecrets  = []
      tolerations       = []
    })
  }
}

# Create a values file for Helm for each cluster
resource "local_file" "helm_values" {
  for_each = var.clusters

  content  = local.helm_values_per_cluster[each.key]
  filename = "${path.module}/config/twingate-values-${each.key}.yaml"
}

# Deploy Twingate components to each cluster using null_resource
resource "null_resource" "deploy_twingate" {
  for_each = var.clusters

  provisioner "local-exec" {
    command = <<-EOT
      set -e  # Exit on any error
      
      echo "=== Configuring kubectl for cluster ${each.key} ==="
      # Create cluster-specific kubeconfig to avoid race conditions
      export KUBECONFIG="/tmp/kubeconfig-${each.key}"
      doctl kubernetes cluster kubeconfig save ${each.key}
      
      echo "=== Verifying cluster connectivity ==="
      # Verify cluster is accessible
      kubectl cluster-info --request-timeout=30s
      
      echo "=== Creating twingate namespace ==="
      # Create namespace
      kubectl create namespace twingate --dry-run=client -o yaml | kubectl apply -f -
      
      echo "=== Deploying Twingate Operator via Helm ==="
      # Deploy Twingate Operator via Helm directly from OCI registry
      helm upgrade --debug --install diy-vpn-${each.value.region} oci://ghcr.io/twingate/helmcharts/twingate-operator \
        --version 0.26.3 \
        --namespace twingate \
        --values ${path.module}/config/twingate-values-${each.key}.yaml \
        --wait \
        --timeout 10m

      echo "=== Twingate Operator deployed to cluster ${each.key} in region ${each.value.region} ==="
      
      echo "=== Waiting for operator to be ready ==="
      # Wait for the operator deployment to be ready
      kubectl wait --for=condition=available --timeout=300s deployment -l app.kubernetes.io/name=twingate-operator -n twingate
      
      echo "=== Deploying TwingateConnector ==="
      # Deploy TwingateConnector - create a temp file with the region value
      cat > /tmp/connector-${each.key}.yaml << 'CONNECTOR_EOF'
apiVersion: twingate.com/v1beta
kind: TwingateConnector
metadata:
  name: vpn-node-${each.value.region}
  namespace: twingate
spec:
  imagePolicy:
    provider: dockerhub
    schedule: "0 0 * * *"
CONNECTOR_EOF
      
      kubectl apply -f /tmp/connector-${each.key}.yaml
      rm /tmp/connector-${each.key}.yaml
      
      echo "=== Deployed Twingate connector to cluster ${each.key} in region ${each.value.region} ==="
      
      # Show the status
      kubectl get pods -n twingate
      kubectl get twingateconnectors -n twingate
      
      # Cleanup cluster-specific kubeconfig
      rm -f "/tmp/kubeconfig-${each.key}"
    EOT

    on_failure = continue
  }

  depends_on = [
    digitalocean_kubernetes_cluster.clusters,
    local_file.helm_values,
    twingate_remote_network.vpn_networks
  ]

  # Trigger replacement when cluster configuration changes
  triggers = {
    cluster_endpoint = digitalocean_kubernetes_cluster.clusters[each.key].endpoint
    region           = each.value.region
    helm_values_hash = md5(local.helm_values_per_cluster[each.key])
  }
}
