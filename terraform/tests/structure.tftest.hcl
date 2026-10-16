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
