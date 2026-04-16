# ansible-terraform

Ansible + Terraform playbooks and demos. Each folder is a self-contained project; open its **README** for variables, prerequisites, and how to run it.

## Azure — foundation

| Project | Description |
| --- | --- |
| [azure_create_resource_group](./azure_create_resource_group/README.md) | Minimal Terraform: create an Azure resource group. |
| [azure_create_resource_group_backend](./azure_create_resource_group_backend/README.md) | Separate resource group used for remote backend storage (split out for demo clarity). |
| [azure_create_remote_storage](./azure_create_remote_storage/README.md) | Storage account and blob container to host Terraform remote state for other stacks. |

## Azure — web demos

These stacks provision small VM-based web footprints on Azure. They differ mainly in **how Terraform and Ansible Automation Platform interact** (local vs HCP, who drives the run, and optional ITSM/CMDB flows).

| Project | Description |
| --- | --- |
| [azure_create_web_demo](./azure_create_web_demo/README.md) | Two VMs plus networking; Ansible can run Terraform and then configure the hosts as a simple web tier. |
| [azure_create_web_demo_hcp](./azure_create_web_demo_hcp/README.md) | Same style of Azure web stack, laid out for **Terraform Cloud / HCP** workspaces with Ansible **terraform** collection operations and `configure_web`. |
| [azure_create_web_demo_hcp_driven](./azure_create_web_demo_hcp_driven/README.md) | Same Azure resources as the HCP demo, but **Terraform** drives the flow using the **ansible/aap** provider (inventory + job launch); no separate Ansible-driven `tf_ops` workflow. |
| [azure_create_web_demo_tfe_aap](./azure_create_web_demo_tfe_aap/README.md) | **Terraform Enterprise / Cloud** runs, state inspection for **ServiceNow CMDB**-style payloads, VM configuration, and optional **GitHub Actions → AAP** workflow launch. |

## AWS — web demo

| Project | Description |
| --- | --- |
| [aws_create_web_demo_hcp](./aws_create_web_demo_hcp/README.md) | **AWS** counterpart to the Azure HCP web demo: VPC, RHEL EC2 instances, and Ansible playbooks for apply/destroy and web configuration via a **Terraform Cloud / HCP** workspace (`aws-web-demo-dev`). |
