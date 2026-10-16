# These are mock-provider plans. They NEVER prove a real AWS account plan or
# deployment and do not call AWS APIs or use configured AWS credentials.
mock_provider "aws" {
  mock_data "aws_partition" {
    defaults = {
      partition = "aws"
    }
  }
}

variables {
  approved_account_id = "000000000000" # Mock only; not a real AWS account.
  api_allowed_cidrs   = ["203.0.113.10/32"]
}

run "public_node_network_is_restricted" {
  command = plan

  assert {
    condition     = length(aws_subnet.public) == 2 && length(aws_subnet.private) == 2
    error_message = "The capstone must define two public and two private subnets."
  }
  assert {
    condition     = length(aws_nat_gateway.this) == 0 && length(aws_eip.nat) == 0
    error_message = "NAT must be an explicit cost-bearing opt-in."
  }
  assert {
    condition     = aws_eks_cluster.this.vpc_config[0].endpoint_private_access && aws_eks_cluster.this.vpc_config[0].public_access_cidrs == toset(["203.0.113.10/32"])
    error_message = "Private API must be enabled; public API must retain the supplied narrow CIDR."
  }
  assert {
    condition     = aws_eks_cluster.this.access_config[0].bootstrap_cluster_creator_admin_permissions == false && length(aws_eks_access_entry.operator) == 0
    error_message = "No implicit cluster creator or operator admin should exist."
  }
  assert {
    condition     = length(aws_vpc_security_group_ingress_rule.ingress_clients) == 0
    error_message = "No public app ingress should exist without an explicit app audience."
  }
  assert {
    condition     = aws_launch_template.node.metadata_options[0].http_tokens == "required" && aws_launch_template.node.block_device_mappings[0].ebs[0].encrypted
    error_message = "Node template must require IMDSv2 and encrypted root storage."
  }
}

run "private_nodes_require_nat_and_explicit_access" {
  command = plan
  variables {
    enable_nat_gateway            = true
    operator_principal_arn        = "arn:aws:iam::123456789012:role/DocumentedTestOperator"
    ingress_client_cidrs          = ["203.0.113.10/32"]
    grant_bootstrap_cluster_admin = false
  }
  assert {
    condition     = length(aws_nat_gateway.this) == 1 && length(aws_eip.nat) == 1 && length(aws_route.private_nat) == 1
    error_message = "Private-node mode requires one NAT/EIP/default route."
  }
  assert {
    condition     = length(aws_eks_access_entry.operator) == 1 && length(aws_eks_access_policy_association.bootstrap) == 0
    error_message = "An explicit namespace editor must not silently receive cluster admin."
  }
  assert {
    condition     = aws_eks_access_policy_association.operator[0].access_scope[0].type == "namespace" && aws_eks_access_policy_association.operator[0].access_scope[0].namespaces == toset(["labledger"])
    error_message = "Default operator authorization must be restricted to LabLedger namespace."
  }
  assert {
    condition     = length(aws_vpc_security_group_ingress_rule.ingress_clients) == 2
    error_message = "Exactly the two fixed ingress ports should be configured per approved CIDR."
  }
}

run "bootstrap_admin_requires_deliberate_opt_in" {
  command = plan
  variables {
    operator_principal_arn        = "arn:aws:iam::123456789012:role/DocumentedTestOperator"
    grant_bootstrap_cluster_admin = true
  }
  assert {
    condition     = length(aws_eks_access_policy_association.bootstrap) == 1
    error_message = "Approved explicit bootstrap opt-in should be representable."
  }
}

run "reject_open_internet_kubernetes_api" {
  command = plan
  variables {
    api_allowed_cidrs = ["0.0.0.0/0"]
  }
  expect_failures = [var.api_allowed_cidrs]
}

run "reject_admin_without_named_identity" {
  command = plan
  variables {
    grant_bootstrap_cluster_admin = true
  }
  expect_failures = [var.grant_bootstrap_cluster_admin]
}

run "reject_unreviewed_node_growth" {
  command = plan
  variables {
    node_max_size = 100
  }
  expect_failures = [var.node_max_size]
}

run "nlb_owns_http_path_without_direct_node_cidrs" {
  command = plan
  variables {
    enable_public_nlb    = true
    ingress_client_cidrs = ["203.0.113.10/32"]
  }
  assert {
    condition     = length(aws_lb.app) == 1 && aws_lb.app[0].load_balancer_type == "network" && !aws_lb.app[0].internal && aws_lb.app[0].enable_cross_zone_load_balancing
    error_message = "Opt-in must configure exactly one public cross-zone NLB."
  }
  assert {
    condition     = aws_lb_listener.http[0].port == 80 && aws_lb_listener.http[0].protocol == "TCP" && aws_lb_target_group.app[0].port == 30080 && aws_lb_target_group.app[0].target_type == "instance"
    error_message = "HTTP listener must target the fixed NGINX instance NodePort."
  }
  assert {
    condition     = aws_lb_target_group.app[0].health_check[0].protocol == "TCP" && aws_lb_target_group.app[0].health_check[0].port == "traffic-port" && length(aws_autoscaling_attachment.app) == 1
    error_message = "NLB requires matching TCP health checks and managed ASG target registration."
  }
  assert {
    condition     = length(aws_security_group.nlb) == 1 && length(aws_lb.app[0].security_groups) == 1 && length(aws_vpc_security_group_ingress_rule.ingress_clients) == 0 && length(aws_vpc_security_group_ingress_rule.ingress_healthcheck) == 0
    error_message = "NLB mode must use a dedicated SG and remove direct client/subnet-CIDR access to node ports."
  }
  assert {
    condition     = aws_vpc_security_group_ingress_rule.nodes_nlb[0].from_port == 30080 && aws_vpc_security_group_ingress_rule.nodes_nlb[0].to_port == 30080 && aws_vpc_security_group_ingress_rule.nodes_nlb[0].cidr_ipv4 == null && length(aws_vpc_security_group_ingress_rule.nlb_clients) == 1
    error_message = "Worker access must be a single SG-referenced HTTP port, with app audience at the NLB."
  }
}

run "managed_metrics_server_requires_its_verified_port" {
  command = plan
  variables {
    enable_metrics_server = true
  }
  assert {
    condition     = length(aws_eks_addon.metrics_server) == 1 && aws_eks_addon.metrics_server[0].addon_name == "metrics-server" && aws_eks_addon.metrics_server[0].addon_version == "v0.9.0-eksbuild.13"
    error_message = "Metrics Server must be explicitly opted in and use the API-verified version."
  }
  assert {
    condition     = contains(keys(aws_vpc_security_group_ingress_rule.nodes_control_plane), "10251") && contains(keys(aws_vpc_security_group_egress_rule.control_plane_nodes), "10251") && aws_eks_addon.metrics_server[0].service_account_role_arn == null
    error_message = "Metrics API requires control-plane port10251 and no extra AWS role."
  }
}

run "reject_public_nlb_without_explicit_app_audience" {
  command = plan
  variables {
    enable_public_nlb = true
  }
  expect_failures = [var.enable_public_nlb]
}
