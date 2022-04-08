# Configure the AWS Provider
provider "aws" {
  region = var.aws-region
}

# 0. Random
resource "random_string" "suffix" {
  length  = 8
  upper   = false
  special = false
}

resource "aws_key_pair" "deployer" {
  key_name   = "${var.name-prefix}-key-${random_string.suffix.result}"
  public_key = var.public-key
}

resource "local_file" "random_string" {
  content  = random_string.suffix.result
  filename = "random_string"

  depends_on = [
    aws_key_pair.deployer,
  ]
}

resource "local_file" "name-prefix" {
  content  = var.name-prefix
  filename = "name_prefix"

  depends_on = [
    aws_key_pair.deployer,
  ]
}

## Create the user-data file
locals {
  userdata = <<USERDATA
[ZSCALER]
CC_URL=${var.cc_vm_prov_url}
SECRET_NAME=${var.secret_name}
HTTP_PROBE_PORT=${var.http-probe-port}
USERDATA
}

resource "local_file" "user-data-file" {
  content  = local.userdata
  filename = "user_data"
}

# rename the ssh key files to match the keyname
resource "null_resource" "rename_sshkey_files" {
  provisioner "local-exec" {
    command = "mv local.pem ${var.name-prefix}-key-${random_string.suffix.result}.pem && mv local.pem.pub ${var.name-prefix}-key-${random_string.suffix.result}.pem.pub"
  }

  depends_on = [
    aws_key_pair.deployer,
  ]
}

# 1. Network Creation
data "aws_availability_zones" "available" {
  state = "available"
}

#VPCs
resource "aws_vpc" "vpc1" {
  cidr_block           = var.vpc-cidr
  enable_dns_hostnames = true

  tags = map(
    "Name", "${var.name-prefix}-vpc1-${random_string.suffix.result}",
    "zs-edge-connector-cluster/${var.name-prefix}-cluster-${random_string.suffix.result}", "shared",
  )
}

#Subnets
resource "aws_subnet" "pubsubnet1" {
  count = 1

  availability_zone = data.aws_availability_zones.available.names[count.index]
  cidr_block        = cidrsubnet(aws_vpc.vpc1.cidr_block, 8, count.index + 101)
  vpc_id            = aws_vpc.vpc1.id

  tags = map(
    "Name", "${var.name-prefix}-vpc1-public-subnet-${count.index + 1}-${random_string.suffix.result}",
    "zs-edge-connector-cluster/${var.name-prefix}-cluster-${random_string.suffix.result}", "shared",
  )
}

resource "aws_subnet" "privatesubnet1" {
  count = var.subnet-count

  availability_zone = data.aws_availability_zones.available.names[count.index]
  cidr_block        = cidrsubnet(aws_vpc.vpc1.cidr_block, 8, count.index + 1)
  vpc_id            = aws_vpc.vpc1.id

  tags = map(
    "Name", "${var.name-prefix}-vpc1-subnet-${count.index + 1}-${random_string.suffix.result}",
    "zs-edge-connector-cluster/${var.name-prefix}-cluster-${random_string.suffix.result}", "shared",
  )
}

#IGW
resource "aws_internet_gateway" "igw1" {
  vpc_id = aws_vpc.vpc1.id

  tags = map(
    "Name", "${var.name-prefix}-vpc1-gw-${random_string.suffix.result}",
    "zs-edge-connector-cluster/${var.name-prefix}-cluster-${random_string.suffix.result}", "shared",
  )
}

#IGW Route Table
resource "aws_route_table" "routetablepublic1" {
  vpc_id = aws_vpc.vpc1.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw1.id
  }

  tags = map(
    "Name", "${var.name-prefix}-igw-rt-${random_string.suffix.result}",
    "zs-edge-connector-cluster/${var.name-prefix}-cluster-${random_string.suffix.result}", "shared",
  )
}

#Route Table Association for public subnet
resource "aws_route_table_association" "routetablepublic1" {
  count = 1

  subnet_id      = aws_subnet.pubsubnet1.*.id[count.index]
  route_table_id = aws_route_table.routetablepublic1.id
}

#NATGW
resource "aws_eip" "eip1" {
  count      = var.byo_eip_address == false ? 1 : 0
  vpc        = true
  depends_on = [aws_internet_gateway.igw1]
}

resource "aws_nat_gateway" "ngw1" {
  allocation_id = var.byo_eip_address == false ? aws_eip.eip1.*.id[0] : var.nat_eip1_id
  subnet_id     = aws_subnet.pubsubnet1.0.id
  depends_on    = [aws_internet_gateway.igw1]
  tags = map(
    "Name", "${var.name-prefix}-vpc1-natgw-1-${random_string.suffix.result}",
    "zs-edge-connector-cluster/${var.name-prefix}-cluster-${random_string.suffix.result}", "shared",
  )
}

# 2. Bastion Host
module "bastion" {
  source        = "../modules/terraform-zsbastion-aws"
  name-prefix   = var.name-prefix
  resource-tag  = random_string.suffix.result
  vpc           = aws_vpc.vpc1.id
  public-subnet = aws_subnet.pubsubnet1.0.id
  instance-key  = aws_key_pair.deployer.key_name
}

# 3. Workload
module "workload1" {
  source       = "../modules/terraform-zsworkload-aws"
  name-prefix  = "${var.name-prefix}-workload1"
  resource-tag = random_string.suffix.result
  vpc          = aws_vpc.vpc1.id
  subnet       = aws_subnet.privatesubnet1.0.id
  instance-key = aws_key_pair.deployer.key_name
}

module "workload2" {
  source       = "../modules/terraform-zsworkload-aws"
  name-prefix  = "${var.name-prefix}-workload2"
  resource-tag = random_string.suffix.result
  vpc          = aws_vpc.vpc1.id
  subnet       = aws_subnet.privatesubnet1.1.id
  instance-key = aws_key_pair.deployer.key_name
}

# 4. 2 CC VMs

# create new subnet for CC mgmt n/w
resource "aws_subnet" "cc-mgmt-subnet" {
  count = 2

  availability_zone = data.aws_availability_zones.available.names[count.index]
  cidr_block        = cidrsubnet(aws_vpc.vpc1.cidr_block, 12, (count.index * 16) + 3936)
  vpc_id            = aws_vpc.vpc1.id

  tags = map(
    "Name", "${var.name-prefix}-vpc1-ec-mgmt-subnet-${count.index + 1}-${random_string.suffix.result}",
    "zs-edge-connector-cluster/${var.name-prefix}-cluster-${random_string.suffix.result}", "shared",
  )
}

#CC Mgmt/Service NATGW Route Table
resource "aws_route_table" "routetable-cc-mgmt-and-service" {
  count  = 1
  vpc_id = aws_vpc.vpc1.id
  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.ngw1.id
  }

  tags = map(
    "Name", "${var.name-prefix}-natgw-cc-mgmt-svc-rt-${count.index + 1}-${random_string.suffix.result}",
    "zs-edge-connector-cluster/${var.name-prefix}-cluster-${random_string.suffix.result}", "shared",
  )
}

#CC Mgmt subnet NATGW Route Table Association
resource "aws_route_table_association" "routetable-cc-mgmt" {
  count          = 2
  subnet_id      = aws_subnet.cc-mgmt-subnet.*.id[count.index]
  route_table_id = aws_route_table.routetable-cc-mgmt-and-service.*.id[0]
}

# create new subnet for CC service n/w
resource "aws_subnet" "cc-service-subnet" {
  count             = 2
  availability_zone = data.aws_availability_zones.available.names[count.index]
  cidr_block        = cidrsubnet(aws_vpc.vpc1.cidr_block, 12, (count.index * 16) + 4000)
  vpc_id            = aws_vpc.vpc1.id

  tags = map(
    "Name", "${var.name-prefix}-ec-service-subnet-${count.index + 1}-${random_string.suffix.result}",
    "zs-edge-connector-cluster/${var.name-prefix}-cluster-${random_string.suffix.result}", "shared",
  )
}

#EC Service subnet NATGW Route Table Association
resource "aws_route_table_association" "routetable-cc-service" {
  count          = 2
  subnet_id      = aws_subnet.cc-service-subnet.*.id[count.index]
  route_table_id = aws_route_table.routetable-cc-mgmt-and-service.*.id[0]
}

module "cc-vm1" {
  source            = "../modules/terraform-zscc-aws"
  name-prefix       = var.name-prefix
  resource-tag      = random_string.suffix.result
  vpc               = aws_vpc.vpc1.id
  mgmt-subnet-id    = aws_subnet.cc-mgmt-subnet.*.id[0]
  service-subnet-id = aws_subnet.cc-service-subnet.*.id[0]
  instance-key      = aws_key_pair.deployer.key_name
  user-data         = local.userdata
  ccvm-instance-type = var.ccvm-instance-type
}

module "cc-vm2" {
  source            = "../modules/terraform-zscc-aws"
  name-prefix       = var.name-prefix
  resource-tag      = "2-${random_string.suffix.result}"
  vpc               = aws_vpc.vpc1.id
  mgmt-subnet-id    = aws_subnet.cc-mgmt-subnet.*.id[1]
  service-subnet-id = aws_subnet.cc-service-subnet.*.id[1]
  instance-key      = aws_key_pair.deployer.key_name
  user-data         = local.userdata
  ccvm-instance-type = var.ccvm-instance-type
}

# 4. Routing thru Cloud Connector for private subnets (workload servers)
# Workload Route Table
resource "aws_route_table" "routetableprivate1" {
  vpc_id = aws_vpc.vpc1.id
  route {
    cidr_block           = "0.0.0.0/0"
    network_interface_id = module.cc-vm1.eni
  }

  tags = map(
    "Name", "${var.name-prefix}-private-to-ccvm1-rt-${random_string.suffix.result}",
    "zs-edge-connector-cluster/${var.name-prefix}-cluster-${random_string.suffix.result}", "shared",
  )
}

resource "aws_route_table" "routetableprivate2" {
  vpc_id = aws_vpc.vpc1.id
  route {
    cidr_block           = "0.0.0.0/0"
    network_interface_id = module.cc-vm2.eni
  }

  tags = map(
    "Name", "${var.name-prefix}-private-to-ccvm2-rt-${random_string.suffix.result}",
    "zs-edge-connector-cluster/${var.name-prefix}-cluster-${random_string.suffix.result}", "shared",
  )
}

# NATGW Route Table Association
resource "aws_route_table_association" "routetableprivate1" {
  subnet_id      = aws_subnet.privatesubnet1.0.id
  route_table_id = aws_route_table.routetableprivate1.id
}

resource "aws_route_table_association" "routetableprivate2" {
  subnet_id      = aws_subnet.privatesubnet1.1.id
  route_table_id = aws_route_table.routetableprivate2.id
}

# 5. Route53 for ZPA
# Route53 Subnets
resource "aws_subnet" "r53-sn1" {
  count             = 2
  availability_zone = data.aws_availability_zones.available.names[count.index]
  cidr_block        = cidrsubnet(aws_vpc.vpc1.cidr_block, 12, (64 + count.index * 16))
  vpc_id            = aws_vpc.vpc1.id

  tags = map(
    "Name", "${var.name-prefix}-ec-r53-subnet-${count.index + 1}-${random_string.suffix.result}",
    "zs-edge-connector-cluster/${var.name-prefix}-cluster-${random_string.suffix.result}", "shared",
  )
}

# Route Table Association
resource "aws_route_table_association" "routetable-r53a" {
  subnet_id      = aws_subnet.r53-sn1.0.id
  route_table_id = aws_route_table.routetableprivate1.id
}

resource "aws_route_table_association" "routetable-r53b" {
  subnet_id      = aws_subnet.r53-sn1.1.id
  route_table_id = aws_route_table.routetableprivate2.id
}

module "route53" {
  source       = "../modules/terraform-zsroute53-aws"
  name-prefix  = var.name-prefix
  resource-tag = random_string.suffix.result
  vpc          = aws_vpc.vpc1.id
  subnet-1     = aws_subnet.r53-sn1.*.id[0]
  subnet-2     = aws_subnet.r53-sn1.*.id[1]
  domain-name  = "proxyinthe.cloud"
}

# 6. Lambda

module "cc-lambda" {
  source           = "../modules/terraform-zslambda-aws"
  name-prefix      = var.name-prefix
  resource-tag     = random_string.suffix.result
  vpc              = aws_vpc.vpc1.id
  cc-vm1-id        = module.cc-vm1.id
  cc-vm2-id        = module.cc-vm2.id
  cc-vm1-snid      = aws_subnet.cc-service-subnet.*.id[0]
  cc-vm2-snid      = aws_subnet.cc-service-subnet.*.id[1]
  cc-vm1-rte-list  = [aws_route_table_association.routetableprivate1.route_table_id]
  cc-vm2-rte-list  = [aws_route_table_association.routetableprivate2.route_table_id]
  http-probe-port  = var.http-probe-port
}
