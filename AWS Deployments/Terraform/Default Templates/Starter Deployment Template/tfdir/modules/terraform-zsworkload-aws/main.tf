data "aws_region" "current" {}

data "aws_vpc" "selected" {
  id = var.vpc
}

data "aws_ami" "centos" {
  most_recent = true

  filter {
    name   = "product-code"
    values = ["aw0evgkw8e5c1q413zgy5pjce"]
  }

  owners = ["aws-marketplace"]
}

resource "aws_iam_role" "node-iam-role" {
  name = "${var.name-prefix}-node-iam-role-${var.resource-tag}"

  assume_role_policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
POLICY
}

resource "aws_iam_role_policy_attachment" "node-AmazonEC2ContainerRegistryReadOnly" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = aws_iam_role.node-iam-role.name
}

resource "aws_security_group" "node-sg" {
  name        = "${var.name-prefix}-node-sg-${var.resource-tag}"
  description = "Security group for all Server nodes in the cluster"
  vpc_id      = data.aws_vpc.selected.id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = map(
    "Name", "${var.name-prefix}-vpc-${var.resource-tag}",
    "zs-workload-cluster/${var.name-prefix}-cluster-${var.resource-tag}", "shared",
  )
}

resource "aws_security_group_rule" "server-node-ingress-self" {
  description              = "Allow node to communicate with each other"
  from_port                = 0
  protocol                 = "-1"
  security_group_id        = aws_security_group.node-sg.id
  source_security_group_id = aws_security_group.node-sg.id
  to_port                  = 65535
  type                     = "ingress"
}

resource "aws_security_group_rule" "server-node-ingress-ssh" {
  description       = "SSH for nodes"
  from_port         = 22
  protocol          = "tcp"
  security_group_id = aws_security_group.node-sg.id
  cidr_blocks       = ["0.0.0.0/0"]
  to_port           = 22
  type              = "ingress"
}

resource "aws_iam_instance_profile" "server_host_profile" {
  name = "${var.name-prefix}-server_host_profile-${var.resource-tag}"
  role = aws_iam_role.node-iam-role.name
}

resource "aws_instance" "server_host" {
  ami                    = data.aws_ami.centos.id
  instance_type          = var.instance-type
  key_name               = var.instance-key
  subnet_id              = var.subnet
  iam_instance_profile   = aws_iam_instance_profile.server_host_profile.name
  vpc_security_group_ids = [aws_security_group.node-sg.id]

  tags = map(
    "Name", "${var.name-prefix}-server_node-${var.resource-tag}",
  )
}
