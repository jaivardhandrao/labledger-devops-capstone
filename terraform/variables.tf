variable "approved_account_id" {
  description = "REQUIRED: exact owner-approved personal/school AWS sandbox account. Provider rejects other credential-chain accounts. This is an account guard, not a credential or authorization."
  type        = string
  validation {
    condition     = can(regex("^[0-9]{12}$", var.approved_account_id))
    error_message = "Supply the exact approved 12-digit AWS sandbox account ID."
  }
}

variable "aws_region" {
  description = "Approved AWS region. The course reference uses Mumbai."
  type        = string
  default     = "ap-south-1"
}

variable "environment" {
  type        = string
  default     = "capstone"
  description = "Resource tag; not an account or authorization boundary."
}

variable "cluster_name" {
  type    = string
  default = "labledger-capstone"
  validation {
    condition     = can(regex("^[a-zA-Z][a-zA-Z0-9_-]{0,79}$", var.cluster_name))
    error_message = "Use an EKS-compatible name of 1–80 characters."
  }
}

variable "kubernetes_version" {
  description = "Confirm current EKS standard-support availability before apply; old versions can attract extended-support charges."
  type        = string
  default     = "1.34"
}

variable "availability_zones" {
  description = "Exactly two distinct AZs in the approved region; adjust when changing aws_region."
  type        = list(string)
  default     = ["ap-south-1a", "ap-south-1b"]
  validation {
    condition     = length(var.availability_zones) == 2 && length(distinct(var.availability_zones)) == 2
    error_message = "Supply exactly two distinct availability zones."
  }
}

variable "vpc_cidr" {
  type    = string
  default = "10.42.0.0/16"
  validation {
    condition     = can(cidrsubnet(var.vpc_cidr, 8, 3))
    error_message = "Supply an IPv4 VPC CIDR with room for four /24-style subnet divisions."
  }
}

variable "enable_nat_gateway" {
  description = "False: nodes use public subnets and public IPv4 (still billed). True: nodes use private subnets with one billed NAT gateway, not HA across AZs."
  type        = bool
  default     = false
}

variable "api_allowed_cidrs" {
  description = "REQUIRED: actual operator egress IPv4 CIDRs for the public EKS API. Do not use 0.0.0.0/0. Private API remains enabled."
  type        = list(string)
  validation {
    condition = length(var.api_allowed_cidrs) > 0 && alltrue([
      for cidr in var.api_allowed_cidrs : can(cidrnetmask(cidr)) && try(tonumber(split("/", cidr)[1]) >= 24, false)
    ])
    error_message = "Supply one or more real, narrow IPv4 CIDRs (/24 through /32). Broad public API access is rejected."
  }
}

variable "operator_principal_arn" {
  description = "Optional exact IAM user/role ARN receiving namespace-scoped LabLedger edit access. Use a role ARN, not an STS assumed-role session ARN. No automatic creator admin access."
  type        = string
  default     = null
  nullable    = true
  validation {
    condition     = var.operator_principal_arn == null ? true : can(regex("^arn:aws:iam::[0-9]{12}:(role|user)/.+$", var.operator_principal_arn))
    error_message = "Use an IAM role/user ARN or null."
  }
}

variable "grant_bootstrap_cluster_admin" {
  description = "Explicit privileged opt-in, only after separate approval: grants operator cluster admin for installing namespaces/controllers/CRDs. Remove after bootstrap."
  type        = bool
  default     = false
  validation {
    condition     = !var.grant_bootstrap_cluster_admin || var.operator_principal_arn != null
    error_message = "Cluster admin opt-in requires an explicit operator_principal_arn."
  }
}

variable "node_instance_type" {
  description = "Review current price and regional availability before approval. One t3.large node is the proposed classroom capacity for observability; not a fixed cost cap."
  type        = string
  default     = "t3.large"
}

variable "node_desired_size" {
  type    = number
  default = 1
}

variable "node_min_size" {
  type    = number
  default = 1
}

variable "node_max_size" {
  type    = number
  default = 1
  validation {
    condition     = var.node_min_size >= 1 && var.node_min_size <= var.node_desired_size && var.node_desired_size <= var.node_max_size && var.node_max_size <= 5
    error_message = "Require 1 <= min <= desired <= max <= 5; increased capacity needs a new cost review."
  }
}

variable "ingress_client_cidrs" {
  description = "Optional approved client IPv4 CIDRs for ingress-nginx fixed NodePorts 30080/30443. Empty means no public client ingress to workers. Separate from EKS API access."
  type        = set(string)
  default     = []
  validation {
    condition     = alltrue([for cidr in var.ingress_client_cidrs : can(cidrnetmask(cidr))])
    error_message = "Use valid IPv4 CIDRs."
  }
}

variable "enable_public_nlb" {
  description = "Explicit opt-in: Terraform owns one public HTTP NLB, listener and instance-target attachment. Requires approved app-client CIDRs; no AWS Load Balancer Controller role."
  type        = bool
  default     = false
  validation {
    condition     = !var.enable_public_nlb || length(var.ingress_client_cidrs) > 0
    error_message = "Public NLB requires an explicitly approved nonempty ingress_client_cidrs audience."
  }
}

variable "enable_metrics_server" {
  description = "Optional EKS-managed Metrics Server; adds no AWS IAM role. Verified compatible with Kubernetes 1.34 on 16 October 2026."
  type        = bool
  default     = false
}

variable "metrics_server_addon_version" {
  description = "Exact AWS EKS add-on version verified by DescribeAddonVersions for Kubernetes 1.34. Recheck compatibility before changing Kubernetes versions."
  type        = string
  default     = "v0.9.0-eksbuild.13"
}
