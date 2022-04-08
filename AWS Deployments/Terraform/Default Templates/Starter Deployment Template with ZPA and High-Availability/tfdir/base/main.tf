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

# 4. Routing thru NAT GW for private subnets (workload servers)
#NATGW Route Table
resource "aws_route_table" "routetableprivate1" {
  vpc_id = aws_vpc.vpc1.id
  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.ngw1.id
  }

  tags = map(
    "Name", "${var.name-prefix}-natgw-rt-1-${random_string.suffix.result}",
    "zs-edge-connector-cluster/${var.name-prefix}-cluster-${random_string.suffix.result}", "shared",
  )
}

#NATGW Route Table Association
resource "aws_route_table_association" "routetableprivate1" {
  subnet_id      = aws_subnet.privatesubnet1.0.id
  route_table_id = aws_route_table.routetableprivate1.id
}
