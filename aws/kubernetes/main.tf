# Create an exit network for each cluster/region
resource "twingate_remote_network" "vpn_networks" {
  for_each = var.clusters

  name     = "aws_${each.value.region}"
  location = "OTHER"
  type     = "EXIT"
}

# Create VPC for each EKS cluster
resource "aws_vpc" "eks_vpcs" {
  for_each = var.clusters

  provider             = aws
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name                                = "twingate-eks-${each.key}"
    "kubernetes.io/cluster/${each.key}" = "shared"
    Environment                         = var.environment
    ManagedBy                           = "terraform"
  }
}

# Create Internet Gateway for each VPC
resource "aws_internet_gateway" "eks_igws" {
  for_each = var.clusters

  provider = aws
  vpc_id   = aws_vpc.eks_vpcs[each.key].id

  tags = {
    Name        = "twingate-eks-igw-${each.key}"
    Environment = var.environment
  }
}

# Data source for availability zones
data "aws_availability_zones" "available" {
  for_each = var.clusters

  provider = aws
  state    = "available"
}

# Create public subnets for each EKS cluster (2 AZs for HA)
resource "aws_subnet" "eks_public_subnets" {
  for_each = {
    for item in flatten([
      for cluster_key, cluster_config in var.clusters : [
        for idx in [0, 1] : {
          key               = "${cluster_key}-public-${idx}"
          cluster_key       = cluster_key
          region            = cluster_config.region
          cidr_block        = cidrsubnet("10.0.0.0/16", 8, idx)
          availability_zone = data.aws_availability_zones.available[cluster_key].names[idx]
        }
      ]
    ]) : item.key => item
  }

  provider                = aws
  vpc_id                  = aws_vpc.eks_vpcs[each.value.cluster_key].id
  cidr_block              = each.value.cidr_block
  availability_zone       = each.value.availability_zone
  map_public_ip_on_launch = true

  tags = {
    Name                                              = "twingate-eks-public-${each.key}"
    "kubernetes.io/cluster/${each.value.cluster_key}" = "shared"
    "kubernetes.io/role/elb"                          = "1"
    Environment                                       = var.environment
  }
}

# Create route table for each VPC
resource "aws_route_table" "eks_route_tables" {
  for_each = var.clusters

  provider = aws
  vpc_id   = aws_vpc.eks_vpcs[each.key].id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.eks_igws[each.key].id
  }

  tags = {
    Name        = "twingate-eks-rt-${each.key}"
    Environment = var.environment
  }
}

# Associate route tables with subnets
resource "aws_route_table_association" "eks_rta" {
  for_each = aws_subnet.eks_public_subnets

  provider       = aws
  subnet_id      = each.value.id
  route_table_id = aws_route_table.eks_route_tables[split("-public-", each.key)[0]].id
}

# IAM role for EKS cluster
resource "aws_iam_role" "eks_cluster_role" {
  for_each = var.clusters

  provider = aws
  name     = "twingate-eks-cluster-role-${each.key}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "eks.amazonaws.com"
      }
    }]
  })

  tags = {
    Name        = "twingate-eks-cluster-role-${each.key}"
    Environment = var.environment
  }
}

# Attach required policies to EKS cluster role
resource "aws_iam_role_policy_attachment" "eks_cluster_policy" {
  for_each = var.clusters

  provider   = aws
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = aws_iam_role.eks_cluster_role[each.key].name
}

# IAM role for EKS node group
resource "aws_iam_role" "eks_node_role" {
  for_each = var.clusters

  provider = aws
  name     = "twingate-eks-node-role-${each.key}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "ec2.amazonaws.com"
      }
    }]
  })

  tags = {
    Name        = "twingate-eks-node-role-${each.key}"
    Environment = var.environment
  }
}

# Attach required policies to EKS node role
resource "aws_iam_role_policy_attachment" "eks_node_policy" {
  for_each = var.clusters

  provider   = aws
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role       = aws_iam_role.eks_node_role[each.key].name
}

resource "aws_iam_role_policy_attachment" "eks_cni_policy" {
  for_each = var.clusters

  provider   = aws
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = aws_iam_role.eks_node_role[each.key].name
}

resource "aws_iam_role_policy_attachment" "eks_container_registry_policy" {
  for_each = var.clusters

  provider   = aws
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = aws_iam_role.eks_node_role[each.key].name
}

# Deploy EKS clusters in multiple regions
resource "aws_eks_cluster" "clusters" {
  for_each = var.clusters

  provider = aws
  name     = each.key
  role_arn = aws_iam_role.eks_cluster_role[each.key].arn
  version  = "1.31"

  vpc_config {
    subnet_ids = [
      for subnet in aws_subnet.eks_public_subnets :
      subnet.id if can(regex("^twingate-eks-public-${each.key}-public-", subnet.tags["Name"]))
    ]
    endpoint_public_access = true
  }

  tags = {
    Name        = each.key
    Environment = var.environment
    ManagedBy   = "terraform"
  }
}

# Create EKS node group for each cluster
resource "aws_eks_node_group" "node_groups" {
  for_each = var.clusters

  provider        = aws
  cluster_name    = aws_eks_cluster.clusters[each.key].name
  node_group_name = "${each.key}-connector-pool"
  node_role_arn   = aws_iam_role.eks_node_role[each.key].arn
  subnet_ids = [
    for subnet in aws_subnet.eks_public_subnets :
    subnet.id if can(regex("^twingate-eks-public-${each.key}-public-", subnet.tags["Name"]))
  ]

  instance_types = [each.value.instance_type]

  scaling_config {
    desired_size = each.value.node_count
    max_size     = each.value.node_count + 2
    min_size     = 1
  }

  update_config {
    max_unavailable = 1
  }

  tags = {
    Name        = "${each.key}-connector-pool"
    Environment = var.environment
  }

  depends_on = [
    aws_iam_role_policy_attachment.eks_node_policy,
    aws_iam_role_policy_attachment.eks_cni_policy,
    aws_iam_role_policy_attachment.eks_container_registry_policy
  ]
}
