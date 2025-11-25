# Create locals for EC2 instances
locals {
  # Flatten the instances configuration to create individual instances
  ec2_instances = merge([
    for instance_name, config in var.instances : {
      for i in range(config.count) :
      config.count == 1 ? "${config.region}-vpn" : "${config.region}-vpn-${format("%02d", i + 1)}" => {
        instance_name = instance_name
        region        = config.region
        instance_type = config.instance_type
        ami           = config.ami
        index         = i + 1
      }
    }
  ]...)

  # Get unique regions for creating exit networks
  unique_regions = toset([for config in var.instances : config.region])

  # Map regions to their first instance config for accessing properties like cidr_block
  region_configs = {
    for instance_name, config in var.instances :
    config.region => config...
  }
}
