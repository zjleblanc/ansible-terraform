# Create Web Demo

This Terraform project contains the configurations required to deploy two Azure Virtual Machines which will serve as managed Ansible nodes to be configured as web servers.

- [Providers](./providers.tf)
- [Variables](./variables.tf)
- [Main](./main.tf)

## Terraform

### Resources

The infrastructure is pretty simple:
- basic Azure networking resources
- security rules to allow for SSH (not production grade)
- a couple of vms
- ssh key pair

Lookup **source_image_reference** configurations for VMs using the Azure CLI:<br>
`az vm image list --publisher RedHat --all --output table`

### Important Variables

| Variable | Purpose |
| --- | --- |
| az_resource_group | Target resource group |
| az_region | Azure region for the resource group / infrastructure |
| web_tags_base | Base tags for resources deploy - I **always** recommend tags |
| web_* | Other variables for standardized naming of deployed resources |

## Ansible Playbook

Playbooks included support executing Terraform operations via Ansible and configuration of the provisioned infrastructure. The complete product is a Workflow Job Template in Ansible Automation Platform which chains together the execution of the playbooks.

| Playbook | Description |
| --- | --- |
| [tf_ops.yml](./ansible/tf_ops.yml) | Based on tags, will either complete the `terraform apply` or `terraform destroy` action |

## AAP Workflow

To tie everything together in an enterprise-grade workflow, you will need to create a few resources in Ansible Automation Platform. Below is a list of the resources I created and relationships between them:

```yaml
Project: Terraform Mgmt # connected to this GitHub repository
Execution_Environment: ee-cloud # using publicly available image -> quay.io/scottharwell/cloud-ee
Credentials:
  - Type: Microsoft Azure Resource Manager
    Purpose: authenticating with ARM API (environment block in tf_ops playbook)
  - Type: Terraform backend configuration
    Purpose: supplies the backend.conf file as encrypted content and sets the TF_BACKEND_CONFIG_FILE environment variable
  - Type: Machine
    Purpose: injects the admin user and private key associated with the key-pair tied to the VMs in Azure for SSH
Job_Templates:
  - Name: Terraform // Web Demo Deploy
    Execution_Environment: ee-cloud # see above
    Project: Terraform Mgmt # see above
    Playbook: tf_ops.yml
    Credentials:
      - Microsoft Azure Resource Manager # see above
      - Terraform backend configuration  # see above
    Survey:
      - Question: SSH public key
        Variable: az_ssh_pubkey
```

## Lessons Learned

Authentication
- Terraform azurerm provider expects **ARM_\*** environment variables to handle login via az client
- Microsoft Azure Resource Manager Credential Type injects **AZURE_\*** - you must map these in a playbook (or use custom cred type)
- Terraform azurerm backend has multiple auth options, I was using a storage account key
  - there are two parameters for the backend that confused me: `key` and `access_key`
  - `key` is required and is used to name the folder in blob storage used for the projects state
  - `access_key` is used to authenticate with the storage account, can be supplied via ARM_ACCESS_KEY
- Built-in Credential Type **Terraform backend configuration** supports injecting the `TF_BACKEND_CONFIG_FILE` environment variable which can be passed to the **cloud.terraform.terraform** module
  - I put my access_key into this _encrypted_ credential. It could also be source from a third-party vault for additional security.
  - You could create a custom credential type to inject all of the **ARM_\*** environment variables needed for your use case, and it may even be cleaner if used often. I chose to show it as raw as possible so readers could see the details and clean it up as desired.