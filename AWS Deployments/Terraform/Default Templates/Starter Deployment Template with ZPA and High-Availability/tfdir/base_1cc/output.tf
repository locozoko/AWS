locals {

  testbedconfig = <<TB

1) Copy the SSH key to the bastion host
scp -i ${var.name-prefix}-key-${random_string.suffix.result}.pem ${var.name-prefix}-key-${random_string.suffix.result}.pem centos@${module.bastion.public_dns}:/home/centos/.

2) SSH to the bastion host
ssh -i ${var.name-prefix}-key-${random_string.suffix.result}.pem centos@${module.bastion.public_dns}

3) SSH to the EC
ssh -i ${var.name-prefix}-key-${random_string.suffix.result}.pem zsroot@${module.cc-vm1.private_ip} -o "proxycommand ssh -W %h:%p -i ${var.name-prefix}-key-${random_string.suffix.result}.pem centos@${module.bastion.public_dns}"

4) SSH to the server host
ssh -i ${var.name-prefix}-key-${random_string.suffix.result}.pem centos@${module.workload1.private_ip} -o "proxycommand ssh -W %h:%p -i ${var.name-prefix}-key-${random_string.suffix.result}.pem centos@${module.bastion.public_dns}"


VPC:         ${aws_vpc.vpc1.id}
Service ENI: ${module.cc-vm1.eni}
NAT GW IP  : ${aws_nat_gateway.ngw1.public_ip}
TB

  testbedconfigpyats = <<TBP
testbed:
  name: aws-${random_string.suffix.result}

devices:
  WORKER:
    os: linux
    type: linux
    connections:
      defaults:
        class: fast.connections.pyats_connector.SshClientConnector
        via: fast
      fast:
        hostname: ${module.workload1.private_ip}
        port: 22
        username: ec2-user
        key_filename: ${var.name-prefix}-key-${random_string.suffix.result}.pem
        tunnel_nodes:
          - hostname: ${module.bastion.public_dns}
            username: centos
            port: 22
            key_filename: ${var.name-prefix}-key-${random_string.suffix.result}.pem
  EC:
    os: linux
    type: linux
    connections:
      defaults:
        class: fast.connections.pyats_connector.ZSNodeConnector
        via: fast
      fast:
        name: /sc/instances/edgeconnector0
        hostname: ${module.cc-vm1.private_ip}
        port: 22
        username: zsroot
        key_filename: ${var.name-prefix}-key-${random_string.suffix.result}.pem
        tunnel_nodes:
          - hostname: ${module.bastion.public_dns}
            username: centos
            port: 22
            key_filename: ${var.name-prefix}-key-${random_string.suffix.result}.pem
TBP
}

resource "local_file" "testbed_yml" {
content = local.testbedconfigpyats
filename = "testbed.yml"
}

output "testbedconfig" {
  value = local.testbedconfig
}

