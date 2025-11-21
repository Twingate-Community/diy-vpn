terraform {
  required_version = ">= 1.0"
  required_providers {
    twingate = {
      source  = "twingate/twingate"
      version = "~> 3.0"
    }
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
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

# Configure the AWS Provider
provider "aws" {
  region     = var.aws_region
  access_key = var.aws_access_key
  secret_key = var.aws_secret_key
  token      = var.aws_session_token != "" ? var.aws_session_token : null
}
