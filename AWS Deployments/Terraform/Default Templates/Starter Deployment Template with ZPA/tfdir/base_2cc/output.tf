locals {

  testbedconfig = <<TB

1) Copy the SSH key to the bastion host
scp -i ${var.name-prefix}-key-${random_string.suffix.result}.pem ${var.name-prefix}-key-${random_string.suffix.result}.pem centos@${module.bastion.public_dns}:/home/centos/.

2) SSH to the bastion host
ssh -i ${var.name-prefix}-key-${random_string.suffix.result}.pem centos@${module.bastion.public_dns}

3) SSH to the EC
ssh -i ${var.name-prefix}-key-${random_string.suffix.result}.pem zsroot@${module.cc-vm1.private_ip} -o "proxycommand ssh -W %h:%p -i ${var.name-prefix}-key-${random_string.suffix.result}.pem centos@${module.bastion.public_dns}"
ssh -i ${var.name-prefix}-key-${random_string.suffix.result}.pem zsroot@${module.cc-vm2.private_ip} -o "proxycommand ssh -W %h:%p -i ${var.name-prefix}-key-${random_string.suffix.result}.pem centos@${module.bastion.public_dns}"

4) SSH to the server host
ssh -i ${var.name-prefix}-key-${random_string.suffix.result}.pem centos@${module.workload1.private_ip} -o "proxycommand ssh -W %h:%p -i ${var.name-prefix}-key-${random_string.suffix.result}.pem centos@${module.bastion.public_dns}"
ssh -i ${var.name-prefix}-key-${random_string.suffix.result}.pem centos@${module.workload2.private_ip} -o "proxycommand ssh -W %h:%p -i ${var.name-prefix}-key-${random_string.suffix.result}.pem centos@${module.bastion.public_dns}"

VPC     :         ${aws_vpc.vpc1.id}
CC1 Instance:     ${module.cc-vm1.id}
CC2 Instance:     ${module.cc-vm2.id}

CC1 Service ENI:  ${module.cc-vm1.eni}
CC2 Service ENI:  ${module.cc-vm2.eni}

NAT GW IP  :      ${aws_nat_gateway.ngw1.public_ip}
TB
}

output "testbedconfig" {
  value = local.testbedconfig
}
