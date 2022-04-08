data "aws_region" "current" {}

data "aws_vpc" "selected" {
  id = var.vpc
}
data "aws_security_group" selected {
  vpc_id = var.vpc
  name   = "default"
}

resource "aws_route53_resolver_endpoint" "zpa-r53-ep" {
  name      = "${var.name-prefix}-r53-resolver-ep-${var.resource-tag}"
  direction = "OUTBOUND"

  security_group_ids = [
    data.aws_security_group.selected.id
  ]

  ip_address {
    subnet_id = var.subnet-1
  }

  ip_address {
    subnet_id = var.subnet-2
  }

  tags = map(
    "Name", "${var.name-prefix}-r53-resolver-ep-${var.resource-tag}",
    "zs-edge-connector-cluster/${var.name-prefix}-cluster-${var.resource-tag}", "shared",
  )
}

resource "aws_route53_resolver_rule" "fwd" {
  domain_name          = var.domain-name
  name                 = "${var.name-prefix}-r53-rule-1-${var.resource-tag}"
  rule_type            = "FORWARD"
  resolver_endpoint_id = aws_route53_resolver_endpoint.zpa-r53-ep.id

  target_ip {
    ip = var.target-address
  }

  tags = map(
    "Name", "${var.name-prefix}-r53-rule-1-${var.resource-tag}",
    "zs-edge-connector-cluster/${var.name-prefix}-cluster-${var.resource-tag}", "shared",
  )
}

resource "aws_route53_resolver_rule_association" "r53-rule-association_1" {
  resolver_rule_id = aws_route53_resolver_rule.fwd.id
  vpc_id           = var.vpc
}
