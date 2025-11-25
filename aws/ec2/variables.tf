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

variable "instances" {
  type = map(object({
    region        = string
    instance_type = optional(string, "t3.micro")
    count         = optional(number, 1)
    ami           = optional(string, "ami-0ecb62995f68bb549") # Ubuntu 24.04 LTS in us-east-1
    cidr_block    = optional(string, "10.0.1.0/24")
  }))
  description = "Map of EC2 instance configurations per region"

  validation {
    condition = alltrue([
      for config in values(var.instances) : contains([
        "us-east-1", "us-east-2", "us-west-1", "us-west-2",
        "eu-west-1", "eu-west-2", "eu-west-3", "eu-central-1",
        "ap-south-1", "ap-southeast-1", "ap-southeast-2", "ap-northeast-1", "ap-northeast-2",
        "sa-east-1", "ca-central-1"
      ], config.region)
    ])
    error_message = "Region must be a valid AWS region."
  }
}

variable "ssh_key_name" {
  type        = string
  description = "Name of the SSH key pair in AWS for EC2 instance access (optional for debugging)"
  default     = ""
}

variable "environment" {
  type        = string
  description = "Environment label for resources"
  default     = "production"
}
