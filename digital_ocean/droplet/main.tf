# Create locals for droplet instances
locals {
  # Flatten the droplets configuration to create individual instances
  droplet_instances = merge([
    for droplet_name, config in var.droplets : {
      for i in range(config.count) :
      config.count == 1 ? "${config.region}-vpn" : "${config.region}-vpn-${format("%02d", i + 1)}" => {
        droplet_name = droplet_name
        region       = config.region
        size         = config.size
        image        = config.image
        index        = i + 1
      }
    }
  ]...)

  # Get unique regions for creating exit networks
  unique_regions = toset([for config in var.droplets : config.region])
}

# Create an exit network for each region
resource "twingate_remote_network" "vpn_networks" {
  for_each = local.unique_regions

  name     = "do_${each.value}"
  location = "OTHER"
  type     = "EXIT"
}

# Create Twingate connectors for each droplet instance
resource "twingate_connector" "droplet_connectors" {
  for_each = local.droplet_instances

  name              = each.key
  remote_network_id = twingate_remote_network.vpn_networks[each.value.region].id
}

# Generate tokens for each connector
resource "twingate_connector_tokens" "droplet_tokens" {
  for_each = local.droplet_instances

  connector_id = twingate_connector.droplet_connectors[each.key].id

  # Add keepers to force token rotation if needed
  keepers = {
    droplet_name = each.key
    region       = each.value.region
  }
}

# Create a shared firewall for all Twingate droplets
resource "digitalocean_firewall" "twingate_firewall" {
  name = "twingate-vpn-firewall"

  # Outbound rules - Allow all outbound traffic for Twingate connectivity
  outbound_rule {
    protocol              = "tcp"
    port_range            = "1-65535"
    destination_addresses = ["0.0.0.0/0", "::/0"]
  }

  outbound_rule {
    protocol              = "udp"
    port_range            = "1-65535"
    destination_addresses = ["0.0.0.0/0", "::/0"]
  }

  outbound_rule {
    protocol              = "icmp"
    destination_addresses = ["0.0.0.0/0", "::/0"]
  }

  # No inbound rules - completely locked down
  # All access happens through Twingate

  # Apply firewall to all droplets
  droplet_ids = [for droplet in digitalocean_droplet.twingate_connectors : droplet.id]
}

# Deploy droplets with Twingate connectors
resource "digitalocean_droplet" "twingate_connectors" {
  for_each = local.droplet_instances

  name   = each.key
  region = each.value.region
  size   = each.value.size
  image  = each.value.image

  # Add SSH keys if provided
  ssh_keys = length(var.ssh_key_names) > 0 ? var.ssh_key_names : null

  # Tags for organization
  tags = [
    "twingate-vpn",
    "region-${each.value.region}",
    "env-${var.environment}"
  ]

  # Cloud-init configuration using the official Twingate installation method
  user_data = templatefile("${path.module}/templates/cloud-init.yaml.tpl", {
    access_token   = twingate_connector_tokens.droplet_tokens[each.key].access_token
    refresh_token  = twingate_connector_tokens.droplet_tokens[each.key].refresh_token
    network        = var.tg_network
    region         = each.value.region
    environment    = var.environment
    connector_name = each.key
  })

  # Ensure tokens are created before droplet
  depends_on = [
    twingate_connector_tokens.droplet_tokens
  ]
}
