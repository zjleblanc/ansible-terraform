# Create Web Demo (Terraform‑driven with AAP)

This project creates the **same Azure resources** as `azure_create_web_demo_hcp`, but **changes the order of operations** so that Terraform drives everything:

1. **Terraform** creates the Azure resources (VMs, networking, etc.).
2. **Terraform** uses the **certified [ansible/aap](https://registry.terraform.io/providers/ansible/aap/latest) provider** to create an AAP inventory, add the new VMs as hosts (with `ansible_host`, `computer_name`, `public_ip_address`), and then **launch a Job Template** that configures the web servers.
3. The **only Ansible playbook** involved is the one that configures the web servers; it is **invoked by the Terraform AAP job**, not by a separate Ansible run.

No `tf_ops.yml` or workflow that runs Terraform from Ansible; Terraform is the single driver.

## Layout

| Path | Purpose |
|------|--------|
| [main.tf](./main.tf) | Azure resources + AAP inventory, group, hosts, and job launch |
| [providers.tf](./providers.tf) | `azurerm` and `ansible/aap` providers |
| [variables.tf](./variables.tf) | Azure and AAP variables |
| [ansible/configure_web.yml](./ansible/configure_web.yml) | Single playbook: configure web servers (used by AAP Job Template) |
| [ansible/vars/main.yml](./ansible/vars/main.yml) | Playbook vars (host vars set by Terraform on AAP hosts) |
| [ansible/templates/index.html.j2](./ansible/templates/index.html.j2) | Template for the demo index page |

## Prerequisites

- **Azure**: Same as `azure_create_web_demo_hcp` (credentials, SSH public key, etc.).
- **Ansible Automation Platform**:
  - AAP controller reachable from where Terraform runs.
  - **Job Template** that runs the **configure_web** playbook (e.g. playbook `configure_web.yml` from a project that contains this repo or a copy of `ansible/`).
  - That Job Template must have **Inventory** set to **“Prompt on launch”** so Terraform can pass the created inventory at launch time.
  - **Organization** and **Machine credential** (SSH) so AAP can run the playbook on the Azure VMs (using `ansible_host` = public IP).

## Variables

### Azure (same as sibling project)

- `az_client_id`, `az_client_secret`, `az_tenant_id`, `az_subscription_id`
- `web_demo_ssh_pubkey` (required)
- Optional: `az_resource_group`, `az_region`, `web_vm_size`, `web_tags_base`, etc.

### AAP (certified provider)

| Variable | Description |
|----------|-------------|
| `aap_host` | AAP controller URL (e.g. `https://aap.example.com`) |
| `aap_token` | API user |
| `aap_organization_name` | Organization name for Job Template lookup (e.g. `Default`) |
| `aap_job_template_name` | **Name** of the Job Template that runs the configure_web playbook |
| `aap_inventory_name` | (Optional) Name for the Terraform-created inventory. Default: `Terraform Web Demo Inventory` |
| `aap_insecure_skip_verify` | (Optional) Skip TLS verification. Default: `false` |
| `aap_timeout` | (Optional) API timeout in seconds. Default: `5` |

## Flow

1. `terraform apply`
   - Creates resource group, vnet, subnet, NSG, public IPs, NICs, SSH key, 2 RHEL VMs, managed disks, and attachments.
2. Terraform then creates AAP resources:
   - **Inventory** (name from `aap_inventory_name`).
   - **Group** `tag_demo_web` (matches `hosts: tag_demo_web` in the playbook).
   - **Hosts** (one per VM), with variables: `ansible_host`, `computer_name`, `public_ip_address`.
3. Terraform looks up the Job Template by **name** and **organization**, then launches a **job** with the new inventory.
   That job runs the configure_web playbook against the new hosts.

## AAP Job Template requirements

- **Playbook**: The one that runs `configure_web.yml` (e.g. `ansible/configure_web.yml` in your AAP project).
- **Inventory**: **Prompt on launch** (required so Terraform can pass the created inventory).
- **Credentials**: Machine credential that can SSH to the Azure VMs (user/key or password as in the sibling project).
- **Execution environment**: One that has `ansible.posix` (for `firewalld`) and any other collections the playbook uses.

## Destroy

`terraform destroy` removes the AAP inventory (and its hosts/group) and the Azure resources. Tear-down order is managed by Terraform; no separate Ansible playbook for destroy.

## Comparison with `azure_create_web_demo_hcp`

| Aspect | azure_create_web_demo_hcp | azure_create_web_demo_hcp_driven |
|--------|---------------------------|----------------------------------|
| Driver | Ansible (tf_ops.yml + workflow) | Terraform |
| Terraform | Invoked by Ansible | Runs first, then drives AAP |
| Ansible playbooks | tf_ops.yml + configure_web.yml | configure_web.yml only (via AAP Job Template) |
| Inventory | Typically dynamic or separate | Created by Terraform (AAP provider) |
| Job run | Via workflow / manual | Triggered by Terraform (`aap_job`) |
