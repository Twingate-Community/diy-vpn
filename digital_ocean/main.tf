# Create an exit network for each cluster/region
resource "twingate_remote_network" "vpn_networks" {
  for_each = var.clusters

  name     = "do_${each.value.region}"
  location = "OTHER"
  type     = "EXIT"
}

# Deploy Kubernetes clusters in multiple regions
resource "digitalocean_kubernetes_cluster" "clusters" {
  for_each = var.clusters

  name    = each.key
  region  = each.value.region
  version = "1.33.1-do.3"

  node_pool {
    name       = "${each.key}-connector-pool"
    size       = each.value.node_size
    node_count = each.value.node_count
  }
}
