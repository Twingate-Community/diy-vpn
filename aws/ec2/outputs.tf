# Output information for all EC2 instances
output "instances" {
  description = "Information about all created EC2 instances"
  value = {
    for name, instance in aws_instance.twingate_connectors : name => {
      id            = instance.id
      name          = name
      region        = instance.availability_zone
      instance_type = instance.instance_type
      public_ip     = instance.public_ip
      private_ip    = instance.private_ip
      state         = instance.instance_state
      vpc_id        = instance.vpc_security_group_ids
      subnet_id     = instance.subnet_id
      tags          = instance.tags
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
  description = "Twingate Connector information for each EC2 instance"
  value = {
    for name, connector in twingate_connector.ec2_connectors : name => {
      id                = connector.id
      name              = connector.name
      remote_network_id = connector.remote_network_id
    }
  }
}

output "instance_regions" {
  description = "List of all regions with EC2 instances"
  value       = tolist(local.unique_regions)
}

output "instance_names" {
  description = "List of all EC2 instance names"
  value       = [for instance in aws_instance.twingate_connectors : instance.tags["Name"]]
}

output "twingate_access_info" {
  description = "Information for accessing EC2 instances via Twingate (zero-trust access)"
  value = {
    message        = "All EC2 instance access is via Twingate network - no direct network access available"
    console_access = "Emergency console access available via AWS Systems Manager Session Manager or EC2 console if SSH keys configured"
    instance_ips = {
      for name, instance in aws_instance.twingate_connectors : name => {
        private_ip = instance.private_ip
        public_ip  = instance.public_ip
        note       = "Access only via Twingate - no inbound ports open"
      }
    }
  }
}

output "security_groups" {
  description = "Security group information for each region"
  value = {
    for region, sg in aws_security_group.twingate_sg : region => {
      id   = sg.id
      name = sg.name
    }
  }
}

output "vpc_info" {
  description = "VPC information for each region"
  value = {
    for region, vpc in aws_vpc.twingate_vpcs : region => {
      vpc_id     = vpc.id
      cidr_block = vpc.cidr_block
      subnet_id  = aws_subnet.twingate_subnets[region].id
    }
  }
}

output "deployment_summary" {
  description = "Summary of the deployment"
  value = {
    total_instances  = length(aws_instance.twingate_connectors)
    unique_regions   = length(local.unique_regions)
    remote_networks  = length(twingate_remote_network.vpn_networks)
    connectors       = length(twingate_connector.ec2_connectors)
    environment      = var.environment
    twingate_network = var.tg_network
  }
}
