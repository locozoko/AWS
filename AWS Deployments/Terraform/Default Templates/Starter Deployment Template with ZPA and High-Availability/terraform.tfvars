## This is only a sample terraform.tfvars file.
## Uncomment and change the below variables according to your specific environment

#####################################################################################################################
                                ##### Cloud Init Provisioning variables  #####
#####################################################################################################################
## 1. Zscaler Cloud Connector Provisioning URL E.g. connector.zscalerbeta.net/wapi/v1/provUrl?name=aws_prov_url
#cc_vm_prov_url                          = "connector.zscalerthree.net/wapi/v1/provUrl?name=aws_prov_url"

## 2. AWS Secrets Manager Secret Name from Secrets Manager E.g ZS/CC/credentials
#secret_name                             =  "ZS/CC/credentials/aws_cc_secret_name"

## 3. Cloud Connector cloud init provisioning listener port. This is required for GWLB and Health Probe deployments. 
## Uncomment and set custom probe port to a single value of 80 or any number between 1024-65535. Default is 0/null.
#http-probe-port                         = 50000


#####################################################################################################################
                ##### Custom variables. Only change if required for your environment  #####
#####################################################################################################################

## 4. Cloud Connector VM Instance size selection. Defaults to t3.medium. Uncomment ccvm-instance-type line with desired vm size to change.
#ccvm-instance-type                     = "t3.medium"
#ccvm-instance-type                     = "t2.medium"
#ccvm-instance-type                     = "m5.large"
#ccvm-instance-type                     = "c5.large"
#ccvm-instance-type                     = "c5a.large"