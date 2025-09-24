# Output information for all droplets
output "droplets" {
  description = "Information about all created droplets"
  value = {
    for name, droplet in digitalocean_droplet.twingate_connectors : name => {
      id                   = droplet.id
      name                 = droplet.name
      region               = droplet.region
      size                 = droplet.size
      ipv4_address         = droplet.ipv4_address
      ipv4_address_private = droplet.ipv4_address_private
      ipv6_address         = droplet.ipv6_address
      status               = droplet.status
      tags                 = droplet.tags
    }
  }
}

output "twingate_remote_networks" {
  description = "Twingate Remote Network information for each region"
  value = {
    for region, network in twingate_remote_network.vpn_networks : region => {
      id   = network.id
      name = network.name
    }
  }
}

output "twingate_connectors" {
  description = "Twingate Connector information for each droplet"
  value = {
    for name, connector in twingate_connector.droplet_connectors : name => {
      id                = connector.id
      name              = connector.name
      remote_network_id = connector.remote_network_id
    }
  }
}

output "droplet_regions" {
  description = "List of all regions with droplets"
  value       = tolist(local.unique_regions)
}

output "droplet_names" {
  description = "List of all droplet names"
  value       = [for droplet in digitalocean_droplet.twingate_connectors : droplet.name]
}

output "twingate_access_info" {
  description = "Information for accessing droplets via Twingate (zero-trust access)"
  value = {
    message        = "All droplet access is via Twingate network - no direct network access available"
    console_access = "Emergency console access available via DigitalOcean dashboard if SSH keys configured"
    droplet_ips = {
      for name, droplet in digitalocean_droplet.twingate_connectors : name => {
        private_ip = droplet.ipv4_address_private
        public_ip  = droplet.ipv4_address
        note       = "Access only via Twingate - no inbound ports open"
      }
    }
  }
}

output "firewall_info" {
  description = "Firewall configuration applied to all droplets"
  value = {
    id   = digitalocean_firewall.twingate_firewall.id
    name = digitalocean_firewall.twingate_firewall.name
  }
}

output "deployment_summary" {
  description = "Summary of the deployment"
  value = {
    total_droplets   = length(digitalocean_droplet.twingate_connectors)
    unique_regions   = length(local.unique_regions)
    remote_networks  = length(twingate_remote_network.vpn_networks)
    connectors       = length(twingate_connector.droplet_connectors)
    environment      = var.environment
    twingate_network = var.tg_network
  }
}
