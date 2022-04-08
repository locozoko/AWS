## 1.0.3 (January 19, 2022)
BUG FIXES:
* BUG-110673 - name-prefix append "-workload1" for consistency between base1 and base2 deployment types
* BUG-111245 - R53 route table fix for secondary Outbound Endpoint affix to secondary subnet
* BUG-111245 - Added second workload module and R53 route table and association for base_2cc_zpa to match base_2cc. Updated outputs to reflect new workloads
* BUG-111245 - Updated Lambda module for base_2cc_zpa to match base_2cc
* BUG-111245 - Updated subnet-count default from 1 to 2 for base_2cc_zpa to match base_2cc additional workloads provisioned
* BUG-110694 - Address Terraform destroy issues with Macs specifying different terraform working directory

NOTES:
* TF description and AWS tag/mapping description cleanup


## 1.0.2 (October 25, 2021)
BUG FIXES:
* ccvm-instance-size variable renamed to ccvm-instance-type in terraform.tfvars

## 1.0.1 (October 1, 2021)
ENHANCEMENTS:
* Cloud Connector Service Interface secondary private IP + Name/description mapping added


## 1.0.0 (August 24, 2021)
NOTES:
* Initial code revision check-in

ENHANCEMENTS:
* terraform.tfvars additions: http-probe-port (for CC listener service + health probing); cc_vm_prov_url and secret_name variables for dynamic user_data file creation; ccvm-instance-type for AWS VM size selections

FEATURES:
* Customer solutioned POV template for greenfield/brownfield AWS Cloud Connector Deployments
* Sanitized README file
* ZSEC updated for deployment selection on destroy
* local file user_data file creation with variable reference for cloud init provisioning
* conditional constraints added for new VM types supported: t3.medium, t2.medium, m5.large, c5.large, and c5a.large

BUG FIXES: 
* Outputs testbed EC SSH syntax fixes
