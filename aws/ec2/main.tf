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
}

# Create an exit network for each region
resource "twingate_remote_network" "vpn_networks" {
  for_each = local.unique_regions

  name     = "aws_${each.value}"
  location = "OTHER"
  type     = "EXIT"
}

# Create Twingate connectors for each EC2 instance
resource "twingate_connector" "ec2_connectors" {
  for_each = local.ec2_instances

  name              = each.key
  remote_network_id = twingate_remote_network.vpn_networks[each.value.region].id
}

# Generate tokens for each connector
resource "twingate_connector_tokens" "ec2_tokens" {
  for_each = local.ec2_instances

  connector_id = twingate_connector.ec2_connectors[each.key].id

  # Add keepers to force token rotation if needed
  keepers = {
    instance_name = each.key
    region        = each.value.region
  }
}

# Create VPC for each region
resource "aws_vpc" "twingate_vpcs" {
  for_each = local.unique_regions

  provider             = aws
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name        = "twingate-vpn-${each.value}"
    Environment = var.environment
    ManagedBy   = "terraform"
  }
}

# Create Internet Gateway for each VPC
resource "aws_internet_gateway" "twingate_igws" {
  for_each = local.unique_regions

  provider = aws
  vpc_id   = aws_vpc.twingate_vpcs[each.value].id

  tags = {
    Name        = "twingate-vpn-igw-${each.value}"
    Environment = var.environment
  }
}

# Create subnet for each region
resource "aws_subnet" "twingate_subnets" {
  for_each = local.unique_regions

  provider                = aws
  vpc_id                  = aws_vpc.twingate_vpcs[each.value].id
  cidr_block              = "10.0.1.0/24"
  map_public_ip_on_launch = true
  availability_zone       = data.aws_availability_zones.available[each.value].names[0]

  tags = {
    Name        = "twingate-vpn-subnet-${each.value}"
    Environment = var.environment
  }
}

# Create route table for each VPC
resource "aws_route_table" "twingate_route_tables" {
  for_each = local.unique_regions

  provider = aws
  vpc_id   = aws_vpc.twingate_vpcs[each.value].id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.twingate_igws[each.value].id
  }

  tags = {
    Name        = "twingate-vpn-rt-${each.value}"
    Environment = var.environment
  }
}

# Associate route table with subnet
resource "aws_route_table_association" "twingate_rta" {
  for_each = local.unique_regions

  provider       = aws
  subnet_id      = aws_subnet.twingate_subnets[each.value].id
  route_table_id = aws_route_table.twingate_route_tables[each.value].id
}

# Data source for availability zones
data "aws_availability_zones" "available" {
  for_each = local.unique_regions

  provider = aws
  state    = "available"
}

# Create security group for Twingate connectors - completely locked down
resource "aws_security_group" "twingate_sg" {
  for_each = local.unique_regions

  provider    = aws
  name        = "twingate-vpn-sg-${each.value}"
  description = "Security group for Twingate VPN connectors - zero-trust with no inbound access"
  vpc_id      = aws_vpc.twingate_vpcs[each.value].id

  # Outbound rules - Allow all outbound traffic for Twingate connectivity
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow all outbound traffic for Twingate connectivity"
  }

  # No inbound rules - completely locked down
  # All access happens through Twingate

  tags = {
    Name        = "twingate-vpn-sg-${each.value}"
    Environment = var.environment
    ManagedBy   = "terraform"
  }
}

# Deploy EC2 instances with Twingate connectors
resource "aws_instance" "twingate_connectors" {
  for_each = local.ec2_instances

  provider      = aws
  ami           = each.value.ami
  instance_type = each.value.instance_type
  subnet_id     = aws_subnet.twingate_subnets[each.value.region].id
  
  vpc_security_group_ids = [
    aws_security_group.twingate_sg[each.value.region].id
  ]

  # Add SSH key if provided
  key_name = var.ssh_key_name != "" ? var.ssh_key_name : null

  # Tags for organization
  tags = {
    Name        = each.key
    Environment = var.environment
    ManagedBy   = "terraform"
    Purpose     = "twingate-vpn"
    Region      = each.value.region
  }

  # Cloud-init configuration using the official Twingate installation method
  user_data = templatefile("${path.module}/templates/cloud-init.yaml.tpl", {
    access_token   = twingate_connector_tokens.ec2_tokens[each.key].access_token
    refresh_token  = twingate_connector_tokens.ec2_tokens[each.key].refresh_token
    network        = var.tg_network
    region         = each.value.region
    environment    = var.environment
    connector_name = each.key
  })

  # Ensure tokens and network resources are created before instance
  depends_on = [
    twingate_connector_tokens.ec2_tokens,
    aws_internet_gateway.twingate_igws,
    aws_route_table_association.twingate_rta
  ]
}
