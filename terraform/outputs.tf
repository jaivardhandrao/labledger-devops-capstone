output "aws_region" {
  value       = var.aws_region
  description = "Region for AWS CLI/kubectl setup."
}

output "cluster_name" {
  value = aws_eks_cluster.this.name
}

output "vpc_id" {
  value = aws_vpc.this.id
}

output "public_subnet_ids" {
  value = values(aws_subnet.public)[*].id
}

output "private_subnet_ids" {
  value = values(aws_subnet.private)[*].id
}

output "node_security_group_id" {
  value       = aws_security_group.nodes.id
  description = "For reviewing any separately approved ingress-controller rules."
}

output "kubectl_setup_command" {
  value       = "aws eks update-kubeconfig --region ${var.aws_region} --name ${aws_eks_cluster.this.name}"
  description = "Run with the exact approved operator identity; this changes local kubeconfig."
}

output "node_network_mode" {
  value = var.enable_nat_gateway ? "private subnets through one billed NAT gateway" : "public subnets with public IPv4 and restricted inbound rules"
}

output "application_nlb_dns_name" {
  value       = var.enable_public_nlb ? aws_lb.app[0].dns_name : null
  description = "Optional public HTTP NLB DNS. Configure the NGINX/app Ingress host to this name; actual controller/target health must be verified."
}

output "application_nlb_target_group_arn" {
  value       = var.enable_public_nlb ? aws_lb_target_group.app[0].arn : null
  description = "For read-only target-health verification after an approved deployment; not evidence of healthy targets."
}
