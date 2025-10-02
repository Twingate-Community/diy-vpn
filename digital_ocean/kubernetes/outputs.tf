# Output information for all clusters
output "clusters" {
  description = "Information about all created clusters"
  value = {
    for name, cluster in digitalocean_kubernetes_cluster.clusters : name => {
      endpoint = cluster.endpoint
      name     = cluster.name
      region   = cluster.region
      id       = cluster.id
    }
  }
}

output "twingate_remote_network_ids" {
  description = "Twingate Remote Network IDs for each cluster"
  value = {
    for name, network in twingate_remote_network.vpn_networks : name => network.id
  }
}

output "cluster_names" {
  description = "List of all cluster names"
  value       = [for cluster in digitalocean_kubernetes_cluster.clusters : cluster.name]
}

output "kubeconfig_commands" {
  description = "Commands to configure kubectl for all clusters"
  value = {
    for name, cluster in digitalocean_kubernetes_cluster.clusters : name =>
    "doctl kubernetes cluster kubeconfig save ${cluster.name}"
  }
}

output "provider_configurations" {
  description = "Provider configurations needed for each cluster"
  value = {
    for name, cluster in digitalocean_kubernetes_cluster.clusters : name => {
      endpoint        = cluster.endpoint
      token_command   = "kubectl config view --raw -o jsonpath='{.users[0].user.token}'"
      ca_cert_command = "kubectl config view --raw -o jsonpath='{.clusters[0].cluster.certificate-authority-data}'"
    }
  }
}
