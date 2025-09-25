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

variable "droplets" {
  type = map(object({
    region = string
    size   = optional(string, "s-1vcpu-1gb")
    count  = optional(number, 1)
    image  = optional(string, "ubuntu-24-04-x64")
  }))
  description = "Map of droplet configurations per region"

  validation {
    condition = alltrue([
      for config in values(var.droplets) : contains([
        "nyc1", "nyc2", "nyc3", "ams2", "ams3", "sfo1", "sfo2", "sfo3",
        "sgp1", "lon1", "fra1", "tor1", "blr1", "syd1"
      ], config.region)
    ])
    error_message = "Region must be a valid DigitalOcean region."
  }
}

variable "ssh_key_names" {
  type        = list(string)
  description = "List of SSH key names for droplet access (optional for debugging)"
  default     = []
}

variable "environment" {
  type        = string
  description = "Environment label for resources"
  default     = "production"
}
