# Create Web Demo

This Terraform project contains the configurations required to deploy two Azure Virtual Machines which will serve as managed Ansible nodes to be configured as web servers.

- [Providers](./providers.tf)
- [Variables](./variables.tf)
- [Main](./main.tf)

## Ansible

Playbooks included support executing Terraform operations via Ansible and configuration of the provisioned infrastructure. The complete product is a Workflow Job Template in Ansible Automation Platform which chains together the execution of the playbooks.

| Playbook | Description |
| --- | --- |
| [tf_ops.yml](./ansible/tf_ops.yml) | Based on tags, will either complete the `terraform apply` or `terraform destroy` action |

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