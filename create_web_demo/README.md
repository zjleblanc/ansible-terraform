# Create Web Demo

This Terraform project contains the configurations required to deploy two Azure Virtual Machines which will serve as managed Ansible nodes to be configured as web servers.

- [Providers](./providers.tf)
- [Variables](./variables.tf)
- [Main](./main.tf)

## Ansible

Playbooks included support executing Terraform operations via Ansible and configuration of the provisioned infrastructure. The complete product is a Workflow Job Template in Ansible Automation Platform which chains together the execution of the playbooks.

| Playbook | Description |
| --- | --- |
| [tf_ops.yml](./ansible/tf_ops.yml) | Based on tags, will either complete the terrform apply or terraform destroy step |