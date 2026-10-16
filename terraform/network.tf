locals {
  subnets = {
    for index, az in var.availability_zones : az => {
      public_cidr  = cidrsubnet(var.vpc_cidr, 8, index)
      private_cidr = cidrsubnet(var.vpc_cidr, 8, index + 2)
    }
  }
  node_subnet_ids = var.enable_nat_gateway ? values(aws_subnet.private)[*].id : values(aws_subnet.public)[*].id
}

resource "aws_vpc" "this" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags                 = { Name = "${var.cluster_name}-vpc" }
}

resource "aws_internet_gateway" "this" {
  vpc_id = aws_vpc.this.id
  tags   = { Name = "${var.cluster_name}-igw" }
}

resource "aws_subnet" "public" {
  for_each                = local.subnets
  vpc_id                  = aws_vpc.this.id
  availability_zone       = each.key
  cidr_block              = each.value.public_cidr
  map_public_ip_on_launch = true
  tags = {
    Name                                        = "${var.cluster_name}-public-${each.key}"
    "kubernetes.io/role/elb"                    = "1"
    "kubernetes.io/cluster/${var.cluster_name}" = "shared"
  }
}

resource "aws_subnet" "private" {
  for_each          = local.subnets
  vpc_id            = aws_vpc.this.id
  availability_zone = each.key
  cidr_block        = each.value.private_cidr
  tags = {
    Name                                        = "${var.cluster_name}-private-${each.key}"
    "kubernetes.io/role/internal-elb"           = "1"
    "kubernetes.io/cluster/${var.cluster_name}" = "shared"
  }
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.this.id
  tags   = { Name = "${var.cluster_name}-public" }
}

resource "aws_route" "internet" {
  route_table_id         = aws_route_table.public.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.this.id
}

resource "aws_route_table_association" "public" {
  for_each       = aws_subnet.public
  subnet_id      = each.value.id
  route_table_id = aws_route_table.public.id
}

resource "aws_eip" "nat" {
  count  = var.enable_nat_gateway ? 1 : 0
  domain = "vpc"
  tags   = { Name = "${var.cluster_name}-nat" }
}

resource "aws_nat_gateway" "this" {
  count         = var.enable_nat_gateway ? 1 : 0
  allocation_id = aws_eip.nat[0].id
  subnet_id     = values(aws_subnet.public)[0].id
  depends_on    = [aws_internet_gateway.this]
  tags          = { Name = "${var.cluster_name}-nat" }
}

resource "aws_route_table" "private" {
  vpc_id = aws_vpc.this.id
  tags   = { Name = "${var.cluster_name}-private" }
}

resource "aws_route" "private_nat" {
  count                  = var.enable_nat_gateway ? 1 : 0
  route_table_id         = aws_route_table.private.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.this[0].id
}

resource "aws_route_table_association" "private" {
  for_each       = aws_subnet.private
  subnet_id      = each.value.id
  route_table_id = aws_route_table.private.id
}

resource "aws_security_group" "control_plane" {
  name_prefix = "${var.cluster_name}-control-plane-"
  description = "Additional EKS control-plane SG; node traffic and narrow operator API only"
  vpc_id      = aws_vpc.this.id
  tags        = { Name = "${var.cluster_name}-control-plane" }
}

resource "aws_security_group" "nodes" {
  name_prefix = "${var.cluster_name}-nodes-"
  description = "EKS workers: no SSH, internal pod traffic, explicit control-plane and ingress paths"
  vpc_id      = aws_vpc.this.id
  tags        = { Name = "${var.cluster_name}-nodes" }
}

resource "aws_vpc_security_group_ingress_rule" "api_nodes" {
  security_group_id            = aws_security_group.control_plane.id
  referenced_security_group_id = aws_security_group.nodes.id
  from_port                    = 443
  to_port                      = 443
  ip_protocol                  = "tcp"
  description                  = "Workers reach Kubernetes private API"
}

resource "aws_vpc_security_group_ingress_rule" "api_operator" {
  for_each          = toset(var.api_allowed_cidrs)
  security_group_id = aws_security_group.control_plane.id
  cidr_ipv4         = each.value
  from_port         = 443
  to_port           = 443
  ip_protocol       = "tcp"
  description       = "Approved operator egress only"
}

resource "aws_vpc_security_group_egress_rule" "control_plane_nodes" {
  for_each                     = toset(["443", "8443", "9443", "10250"])
  security_group_id            = aws_security_group.control_plane.id
  referenced_security_group_id = aws_security_group.nodes.id
  from_port                    = tonumber(each.value)
  to_port                      = tonumber(each.value)
  ip_protocol                  = "tcp"
  description                  = "API to kubelet and admission webhooks"
}

resource "aws_vpc_security_group_ingress_rule" "nodes_control_plane" {
  for_each                     = toset(["443", "8443", "9443", "10250"])
  security_group_id            = aws_security_group.nodes.id
  referenced_security_group_id = aws_security_group.control_plane.id
  from_port                    = tonumber(each.value)
  to_port                      = tonumber(each.value)
  ip_protocol                  = "tcp"
  description                  = "Control-plane initiated kubelet and admission traffic"
}

resource "aws_vpc_security_group_ingress_rule" "nodes_internal" {
  security_group_id            = aws_security_group.nodes.id
  referenced_security_group_id = aws_security_group.nodes.id
  ip_protocol                  = "-1"
  description                  = "VPC CNI pod traffic between trusted cluster nodes"
}

# Internet egress is intentionally allowed for node bootstrap, GHCR image pulls,
# EKS APIs and add-on downloads. This is not an inbound Internet permit.
resource "aws_vpc_security_group_egress_rule" "nodes_outbound" {
  security_group_id = aws_security_group.nodes.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
  description       = "Node egress; restrict further with approved endpoints and egress policy"
}

locals {
  ingress_rules = {
    for item in setproduct(var.ingress_client_cidrs, [30080, 30443]) : "${item[0]}:${item[1]}" => {
      cidr = item[0]
      port = item[1]
    }
  }
  healthcheck_rules = {
    for item in setproduct(values(local.subnets)[*].public_cidr, [30080, 30443]) : "${item[0]}:${item[1]}" => {
      cidr = item[0]
      port = item[1]
    }
  }
}

resource "aws_vpc_security_group_ingress_rule" "ingress_clients" {
  for_each          = local.ingress_rules
  security_group_id = aws_security_group.nodes.id
  cidr_ipv4         = each.value.cidr
  from_port         = each.value.port
  to_port           = each.value.port
  ip_protocol       = "tcp"
  description       = "Explicitly approved client to ingress-nginx fixed NodePort"
}

resource "aws_vpc_security_group_ingress_rule" "ingress_healthcheck" {
  for_each          = local.healthcheck_rules
  security_group_id = aws_security_group.nodes.id
  cidr_ipv4         = each.value.cidr
  from_port         = each.value.port
  to_port           = each.value.port
  ip_protocol       = "tcp"
  description       = "Load balancer health probes from public subnet CIDRs"
}
