// AWS Credentials
variable "aws_access_key" {
  type        = string
  description = "AWS Access Key ID"
  sensitive   = true
}

variable "aws_secret_key" {
  type        = string
  description = "AWS Secret Access Key"
  sensitive   = true
}

variable "aws_session_token" {
  type        = string
  description = "AWS Session Token (required for temporary credentials from AWS SSO)"
  sensitive   = true
  default     = ""
}

variable "aws_region" {
  type        = string
  description = "Primary AWS region for provider configuration"
  default     = "us-east-1"
}

// This can be generated from the Twingate Admin Console under Settings > API
variable "tg_api_token" {
  type        = string
  description = "Twingate API token"
  sensitive   = true
}

variable "tg_network" {
  type        = string
  description = "Twingate tenant name (e.g. {tg_network}.twingate.com)"
}

variable "clusters" {
  type = map(object({
    region        = string
    instance_type = optional(string, "t3.medium")
    node_count    = optional(number, 2)
  }))
  description = "Map of EKS cluster configurations keyed by cluster name"

  validation {
    condition = alltrue([
      for config in values(var.clusters) : contains([
        "us-east-1", "us-east-2", "us-west-1", "us-west-2",
        "eu-west-1", "eu-west-2", "eu-west-3", "eu-central-1",
        "ap-south-1", "ap-southeast-1", "ap-southeast-2", "ap-northeast-1", "ap-northeast-2",
        "sa-east-1", "ca-central-1"
      ], config.region)
    ])
    error_message = "Region must be a valid AWS region."
  }
}

variable "environment" {
  type        = string
  description = "Environment label for resources"
  default     = "production"
}
