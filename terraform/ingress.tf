# Terraform, not a Kubernetes cloud controller, owns this optional public NLB.
# The separately installed supported NGINX controller must use NodePort 30080.
resource "aws_security_group" "nlb" {
  count       = var.enable_public_nlb ? 1 : 0
  name_prefix = "${var.cluster_name}-nlb-"
  description = "Public HTTP only from approved app audience; NLB backend path scoped to worker SG"
  vpc_id      = aws_vpc.this.id
  tags        = { Name = "${var.cluster_name}-nlb" }
}

resource "aws_vpc_security_group_ingress_rule" "nlb_clients" {
  for_each          = var.enable_public_nlb ? var.ingress_client_cidrs : toset([])
  security_group_id = aws_security_group.nlb[0].id
  cidr_ipv4         = each.value
  from_port         = 80
  to_port           = 80
  ip_protocol       = "tcp"
  description       = "Explicit approved application audience; not EKS API access"
}

resource "aws_vpc_security_group_egress_rule" "nlb_nodes" {
  count                        = var.enable_public_nlb ? 1 : 0
  security_group_id            = aws_security_group.nlb[0].id
  referenced_security_group_id = aws_security_group.nodes.id
  from_port                    = 30080
  to_port                      = 30080
  ip_protocol                  = "tcp"
  description                  = "NLB data and TCP health checks to fixed HTTP NodePort only"
}

resource "aws_vpc_security_group_ingress_rule" "nodes_nlb" {
  count                        = var.enable_public_nlb ? 1 : 0
  security_group_id            = aws_security_group.nodes.id
  referenced_security_group_id = aws_security_group.nlb[0].id
  from_port                    = 30080
  to_port                      = 30080
  ip_protocol                  = "tcp"
  description                  = "HTTP NodePort only through approved NLB security group"
}

resource "aws_lb" "app" {
  count                            = var.enable_public_nlb ? 1 : 0
  name_prefix                      = "labl-"
  internal                         = false
  load_balancer_type               = "network"
  ip_address_type                  = "ipv4"
  subnets                          = values(aws_subnet.public)[*].id
  security_groups                  = [aws_security_group.nlb[0].id]
  enable_cross_zone_load_balancing = true
  enable_deletion_protection       = false # Disposable project-only teardown.
  tags                             = { Name = "${var.cluster_name}-http" }
  depends_on                       = [aws_internet_gateway.this, aws_route.internet]
}

resource "aws_lb_target_group" "app" {
  count                  = var.enable_public_nlb ? 1 : 0
  name_prefix            = "labl-"
  port                   = 30080
  protocol               = "TCP"
  target_type            = "instance"
  vpc_id                 = aws_vpc.this.id
  preserve_client_ip     = true
  deregistration_delay   = 10
  connection_termination = true
  health_check {
    enabled             = true
    protocol            = "TCP"
    port                = "traffic-port"
    healthy_threshold   = 2
    unhealthy_threshold = 2
    interval            = 10
  }
  tags = { Name = "${var.cluster_name}-http" }
}

resource "aws_lb_listener" "http" {
  count             = var.enable_public_nlb ? 1 : 0
  load_balancer_arn = aws_lb.app[0].arn
  port              = 80
  protocol          = "TCP"
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.app[0].arn
  }
}

# ASG attachment registers the managed worker and its replacements without
# manually copying instance IDs or granting a Kubernetes controller AWS access.
resource "aws_autoscaling_attachment" "app" {
  count                  = var.enable_public_nlb ? 1 : 0
  autoscaling_group_name = aws_eks_node_group.this.resources[0].autoscaling_groups[0].name
  lb_target_group_arn    = aws_lb_target_group.app[0].arn
}

resource "aws_eks_addon" "metrics_server" {
  count                       = var.enable_metrics_server ? 1 : 0
  cluster_name                = aws_eks_cluster.this.name
  addon_name                  = "metrics-server"
  addon_version               = var.metrics_server_addon_version
  resolve_conflicts_on_create = "OVERWRITE"
  resolve_conflicts_on_update = "PRESERVE"
  # No service_account_role_arn: DescribeAddonVersions says IAM not required.
  configuration_values = jsonencode({ containerPort = 10251 })
  depends_on = [
    aws_eks_node_group.this,
    aws_vpc_security_group_ingress_rule.nodes_control_plane,
    aws_vpc_security_group_egress_rule.control_plane_nodes,
  ]
}
