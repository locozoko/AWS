data "aws_region" "current" {}

data "aws_vpc" "selected" {
  id = var.vpc
}

data "aws_ami" "cloudconnector" {
  most_recent = true

  filter {
    name   = "product-code"
    values = ["2l8tfysndbav4tv2nfjwak3cu"]
  }

  owners = ["aws-marketplace"]
}


resource "aws_iam_role" "cc-node-iam-role" {
  name = "${var.name-prefix}-cc-node-iam-role-${var.resource-tag}"

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

resource "aws_iam_role_policy_attachment" "SecretsManagerReadWrite" {
  policy_arn = "arn:aws:iam::aws:policy/${var.iam-role-policy-smrw}"
  role       = aws_iam_role.cc-node-iam-role.name
}

resource "aws_iam_role_policy_attachment" "SSMManagedInstanceCore" {
  policy_arn = "arn:aws:iam::aws:policy/${var.iam-role-policy-ssmcore}"
  role       = aws_iam_role.cc-node-iam-role.name
}

resource "aws_security_group" "cc-node-sg" {
  name        = "${var.name-prefix}-cc-node-sg-${var.resource-tag}"
  description = "Security group for all CC nodes in the cluster"
  vpc_id      = var.vpc

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = map(
    "Name", "${var.name-prefix}-vpc-${var.resource-tag}",
    "zs-edge-connector-cluster/${var.name-prefix}-cluster-${var.resource-tag}", "shared",
  )
}

resource "aws_security_group_rule" "all-vpc-ingress-ec" {
  description       = "Allow all VPC traffic"
  from_port         = 0
  to_port           = 65535
  protocol          = "-1"
  security_group_id = aws_security_group.cc-node-sg.id
  cidr_blocks       = [data.aws_vpc.selected.cidr_block]
  type              = "ingress"
}

resource "aws_security_group_rule" "cc-node-ingress-ssh" {
  description       = "Allow SSH to Cloud Connector VM"
  from_port         = 22
  to_port           = 22
  protocol          = "tcp"
  security_group_id = aws_security_group.cc-node-sg.id
  cidr_blocks       = ["0.0.0.0/0"]
  type              = "ingress"
}

resource "aws_iam_instance_profile" "cc-host-profile" {
  name = "${var.name-prefix}-cc-host-profile-${var.resource-tag}"
  role = aws_iam_role.cc-node-iam-role.name
}

resource "aws_instance" "cc-vm" {
  ami                         = data.aws_ami.cloudconnector.id
  instance_type               = var.ccvm-instance-type
  iam_instance_profile        = aws_iam_instance_profile.cc-host-profile.name
  vpc_security_group_ids      = [aws_security_group.cc-node-sg.id]
  subnet_id                   = var.mgmt-subnet-id
  key_name                    = var.instance-key
  associate_public_ip_address = false
  user_data                   = base64encode(var.user-data)
  tags = map(
    "Name", "${var.name-prefix}-cc-vm-${var.resource-tag}",
  )
}

resource "aws_network_interface" "cc-vm-service-nic" {
  description       = "Interface for service traffic"
  subnet_id         = var.service-subnet-id
  security_groups   = [aws_security_group.cc-node-sg.id]
  source_dest_check = false
  private_ips_count = 1
  attachment {
    instance     = aws_instance.cc-vm.id
    device_index = 1
  }
  tags = map(
    "Name", "${var.name-prefix}-cc-vm-${var.resource-tag}-SrvcIF",
  )
}
