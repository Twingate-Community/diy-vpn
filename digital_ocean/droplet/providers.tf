terraform {
  required_version = ">= 1.0"
  required_providers {
    twingate = {
      source  = "twingate/twingate"
      version = "~> 3.0"
    }
    digitalocean = {
      source  = "digitalocean/digitalocean"
      version = "~> 2.0"
    }
    local = {
      source  = "hashicorp/local"
      version = "~> 2.0"
    }
  }
}

# Configure the Twingate Provider
provider "twingate" {
  api_token = var.tg_api_token
  network   = var.tg_network
}

# Configure the DigitalOcean Provider
provider "digitalocean" {
  token = var.do_token
}
