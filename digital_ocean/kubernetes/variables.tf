// This can be generated from the DigitalOcean Control Panel under API > Tokens
variable "do_token" {
  type        = string
  description = "DigitalOcean API token"
}

// This can be generated from the Twingate Admin Console under Settings > API
variable "tg_api_token" {
  type        = string
  description = "Twingate API token"
}

variable "tg_network" {
  type        = string
  description = "Twingate tenant name (e.g. {tg_network}.twingate.com)"
}

variable "clusters" {
  type = map(object({
    region     = string
    node_size  = optional(string, "s-1vcpu-2gb")
    node_count = optional(number, 1)
  }))
  description = "Map of cluster configurations keyed by cluster name"
}
