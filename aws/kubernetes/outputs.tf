# Output information for all EKS clusters
output "clusters" {
  description = "Information about all created EKS clusters"
  value = {
    for name, cluster in aws_eks_cluster.clusters : name => {
      endpoint                   = cluster.endpoint
      name                       = cluster.name
      arn                        = cluster.arn
      id                         = cluster.id
      version                    = cluster.version
      platform_version           = cluster.platform_version
      certificate_authority_data = cluster.certificate_authority[0].data
    }
  }
  sensitive = true
}

output "twingate_remote_network_ids" {
  description = "Twingate Remote Network IDs for each cluster"
  value = {
    for name, network in twingate_remote_network.vpn_networks : name => network.id
  }
}

output "cluster_names" {
  description = "List of all EKS cluster names"
  value       = [for cluster in aws_eks_cluster.clusters : cluster.name]
}

output "kubeconfig_commands" {
  description = "Commands to configure kubectl for all EKS clusters"
  value = {
    for name, cluster in aws_eks_cluster.clusters : name =>
    "aws eks update-kubeconfig --name ${cluster.name} --region ${var.clusters[name].region}"
  }
}

output "vpc_info" {
  description = "VPC information for each cluster"
  value = {
    for name, vpc in aws_vpc.eks_vpcs : name => {
      vpc_id     = vpc.id
      cidr_block = vpc.cidr_block
    }
  }
}

output "node_group_info" {
  description = "Node group information for each cluster"
  value = {
    for name, ng in aws_eks_node_group.node_groups : name => {
      node_group_name = ng.node_group_name
      status          = ng.status
      capacity_type   = ng.capacity_type
      instance_types  = ng.instance_types
      desired_size    = ng.scaling_config[0].desired_size
    }
  }
}

output "deployment_summary" {
  description = "Summary of the EKS deployment"
  value = {
    total_clusters     = length(aws_eks_cluster.clusters)
    unique_regions     = length(distinct([for c in var.clusters : c.region]))
    remote_networks    = length(twingate_remote_network.vpn_networks)
    environment        = var.environment
    twingate_network   = var.tg_network
    kubernetes_version = "1.31"
  }
}
