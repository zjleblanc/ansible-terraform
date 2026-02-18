# AWS Web Demo (Terraform Cloud / HCP)

This project is the **AWS counterpart** to `azure_create_web_demo_hcp`. It provisions **two RHEL web servers** on AWS and is intended to run from **Terraform Cloud / HCP** with workspace name **`aws-web-demo-dev`**.

## Layout

| Path | Purpose |
|------|---------|
| [main.tf](./main.tf) | VPC, subnet, security group, key pair, 2× EC2 instances (RHEL) |
| [providers.tf](./providers.tf) | Terraform Cloud block + AWS provider (credentials from variables) |
| [variables.tf](./variables.tf) | AWS auth (access key/secret) and web demo variables |
| [ansible/tf_ops.yml](./ansible/tf_ops.yml) | Run Terraform apply/destroy from Ansible (cloud.terraform.terraform); set `TF_WORKSPACE=aws-web-demo-dev` and AWS/SSH vars |
| [ansible/configure_web.yml](./ansible/configure_web.yml) | Playbook: configure web servers (httpd, firewalld, index page) |
| [ansible/vars/main.yml](./ansible/vars/main.yml) | Playbook vars |
| [ansible/templates/index.html.j2](./ansible/templates/index.html.j2) | Template for the demo index page |

## TFE workspace

- **Workspace name:** `aws-web-demo-dev`
- Create the workspace in Terraform Enterprise/Cloud and connect it to this repo (or use CLI-driven workflow). Configure the variables below in the workspace.

## AWS authentication (variables for TFE)

Credentials are supplied via Terraform variables so they can be set in the TFE workspace (e.g. as **sensitive** for the secret).

| Variable | Description | Sensitive |
|----------|-------------|-----------|
| `aws_access_key_id` | AWS access key ID | No |
| `aws_secret_access_key` | AWS secret access key | **Yes** (mark in TFE) |

Optional: use a **TFE credential type** that maps to AWS (e.g. env vars `AWS_ACCESS_KEY_ID` / `AWS_SECRET_ACCESS_KEY`) and leave these variables unset when running in TFE; then configure the provider to use the environment. This layout uses **variables** so credentials are explicit in the workspace.

## Required variables

| Variable | Description |
|----------|-------------|
| `aws_access_key_id` | AWS access key ID for API authentication |
| `aws_secret_access_key` | AWS secret access key (set as **sensitive** in TFE) |
| `web_demo_ssh_pubkey` | Contents of the SSH **public** key used to log in to EC2 (e.g. `~/.ssh/id_rsa.pub`) |

## Optional variables (defaults)

| Variable | Default | Description |
|----------|---------|-------------|
| `aws_region` | `us-east-1` | AWS region |
| `web_vpc_cidr` | `10.0.0.0/16` | VPC CIDR |
| `web_subnet_cidr` | `10.0.2.0/24` | Subnet CIDR |
| `web_vm_name` | `web-demo-vm` | Base name for EC2 instances |
| `web_instance_type` | `t3.small` | EC2 instance type |
| `web_demo_admin_username` | `ec2-user` | SSH user (RHEL on AWS uses `ec2-user`) |
| `web_demo_key_name` | `web-demo-key` | Name for the SSH key pair in AWS |
| `web_tags_base` | `{ owner, demo, deployment, config }` | Common resource tags |

## What gets created

1. **Networking:** VPC, internet gateway, public subnet, route table (0.0.0.0/0 → IGW).
2. **Security group:** Inbound SSH (22), HTTP (80), HTTPS (443); outbound all.
3. **SSH key pair:** Created from `web_demo_ssh_pubkey`.
4. **Two EC2 instances:** Latest RHEL 8 AMI (x86_64), `t3.small` by default, in the public subnet with public IPs.

## Outputs

- `instance_ids` – EC2 instance IDs  
- `public_ips` – Public IPs of the web servers  
- `private_ips` – Private IPs  
- `instance_names` – Name tags of the instances  

Use `public_ips` (or an inventory built from Terraform output) to run the Ansible playbook or to register hosts in AAP.

## Running Terraform from Ansible (tf_ops.yml)

To drive Terraform from Ansible (e.g. from an AAP job or locally):

```bash
cd ansible
export TF_WORKSPACE=aws-web-demo-dev
ansible-playbook tf_ops.yml -e "aws_access_key_id=YOUR_KEY" -e "aws_secret_access_key=YOUR_SECRET" -e "aws_ssh_pubkey=\"$(cat ~/.ssh/id_rsa.pub)\""
```

Required variables for `tf_ops.yml`:

- `aws_access_key_id` – AWS access key
- `aws_secret_access_key` – AWS secret key
- `aws_ssh_pubkey` – SSH public key contents (passed to Terraform as `web_demo_ssh_pubkey`)

Optional: `aws_region` (default `us-east-1`), `aws_ec2_instance_type` (default `t3.small`). Workspace can also be set via env `TF_WORKSPACE`.

To destroy: run the playbook with tag `remove`:  
`ansible-playbook tf_ops.yml --tags remove -e "..."`

## Running Ansible after Terraform

From the project root:

```bash
cd ansible
# Build inventory from Terraform output (example; adjust for your setup)
# ansible_host = public IP, computer_name = instance name, public_ip_address = public IP
ansible-playbook configure_web.yml -i "host1,host2" -e "_hosts=tf_group_web_demo" ...
```

Or use Terraform outputs to build a dynamic inventory or feed AAP. Hosts need `ansible_host`, `computer_name`, and `public_ip_address` for the playbook template (see [configure_web.yml](./ansible/configure_web.yml)).

## Destroy

Run `terraform destroy` from the workspace (or locally with the same variables). All created AWS resources (instances, key pair, security group, subnet, route table, IGW, VPC) are removed.

## Comparison with azure_create_web_demo_hcp

| Aspect | azure_create_web_demo_hcp | aws_create_web_demo_hcp |
|--------|---------------------------|--------------------------|
| Cloud | Azure | AWS |
| Auth | Service principal (client id/secret/tenant/subscription) | Access key + secret key |
| Compute | 2× Azure Linux VMs (RHEL) | 2× EC2 (RHEL 8 AMI) |
| Network | Resource group, vnet, subnet, NSG | VPC, subnet, IGW, security group |
| SSH | azurerm_ssh_public_key | aws_key_pair (from variable) |
| TFE workspace | (per your Azure setup) | **aws-web-demo-dev** |
