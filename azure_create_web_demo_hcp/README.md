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

To tie everything together in an enterprise-grade workflow, you will need to create a few resources in Ansible Automation Platform. Below is a list of the resources I created and relationships between them. The configuration results in a workflow pictured immediately below:

![Terraform Create Web Demo Workflow in Ansible Automation Platform](../.attachments/az_create_web_demo_aap_workflow.png)

```yaml
# projects.yml
---
controller_projects:
  - name: Terraform Mgmt
    scm_url: https://github.com/zjleblanc/ansible-terraform.git
    organization: Autodotes
    scm_branch: master
    scm_type: git
```

```yaml
# execution_environments.yml
---
controller_execution_environments:
  - name: ee-default
    description: my default execution environment with all the collections and libraries \
    image: quay.io/zleblanc/ee-default:87a71cbb
  - name: ee-cloud
    description: Scott Harwell's Cloud EE hosted in quay
    image: quay.io/scottharwell/cloud-ee

```

```yaml
# credentials.yml
---
controller_credentials:
- name: AAP (id_rsa)
  organization: Autodotes
  description: SSH credential for connecting as zach user
  credential_type: Machine
  inputs:
    become_method: ''
    become_username: ''
    ssh_key_data: "{{ controller_credential_ansible_ssh_key }}"
    username: zach
- name: Terraform Backend Azure Storage Credential
  description: Terraform backend configuration for Azure storage account in your Azure subscription
  organization: Autodotes
  credential_type: Terraform backend configuration
  inputs:
    configuration: |
      resource_group_name  = "openenv-szvs7"
      storage_account_name = "zjltfstatemgmtsa"
      container_name       = "tfstate"
      access_key           = "{{ controller_credential_az_tf_backend_key  }}"
- name: Azure RM Service Principal
  description: service principal with perms to deploy in your Azure subscription
  organization: Autodotes
  credential_type: Microsoft Azure Resource Manager
  inputs:
    client: "{{ controller_credential_azure_client }}"
    secret: "{{ controller_credential_azure_secret }}"
    subscription: "{{ controller_credential_azure_subscription }}"
    tenant: "{{ controller_credential_azure_tenant }}"
```

```yaml
# job_templates.yml
---
controller_templates:
- name: Terraform // Web Demo Deploy
  description: Deploy web demo to Azure using terraform modules
  labels:
    - Demo
  project: Terraform Mgmt
  organization: Autodotes
  inventory: Ansible-Terraform Inventory
  playbook: create_web_demo/ansible/tf_ops.yml
  execution_environment: ee-cloud
  credentials:
    - Azure RM Service Principal
    - Terraform Backend Azure Storage Credential
  ask_tags_on_launch: true
  survey_spec:
    name: job template survey
    description: SSH cred for bootstrapping VM
    spec:
    - question_name: SSH Public Key
      question_description: SSH public key which will enable configuration after provisioning
      max: 1024
      min: 0
      required: true
      type: password
      variable: az_ssh_pubkey
- name: Terraform // Web Demo Configure
  description: Configure webservers provisioned by Terraform
  labels:
    - Demo
  project: Terraform Mgmt
  organization: Autodotes
  inventory: Ansible-Terraform Inventory
  playbook: create_web_demo/ansible/configure_web.yml
  execution_environment: ee-default
  credentials:
    - AAP (id_rsa)
```

```yaml
# workflow_job_templates.yml
---
controller_workflows:
- name: Terraform // Deploy and Configure Workflow
  organization: Autodotes
  survey_enabled: true
  survey_spec:
    name: workflow survey
    description: SSH public key passthrough
    spec:
    - question_name: SSH Public Key
      question_description: SSH public key which will enable configuration after provisioning
      max: 1024
      min: 0
      required: true
      type: password
      variable: az_ssh_pubkey
  workflow_nodes:
  - identifier: Sync Project
    related:
      success_nodes:
      - identifier: Terraform Create
    unified_job_template:
      name: Terraform Mgmt
      organization:
        name: Autodotes
        type: organization
      type: project
  - identifier: Terraform Create
    related:
      failure_nodes:
      - identifier: Terraform Destroy
      success_nodes:
      - identifier: Sync Terraform Inventory
    unified_job_template:
      name: Terraform // Web Demo Deploy
      organization:
        name: Autodotes
        type: organization
      type: job_template
  - identifier: Sync Terraform Inventory
    related:
      success_nodes:
      - identifier: Configure Web Servers
    unified_job_template:
      inventory:
        name: Ansible-Terraform Inventory
        organization:
          name: Autodotes
          type: organization
        type: inventory
      name: openenv-szvs7
      type: inventory_source
  - identifier: Configure Web Servers
    related:
      failure_nodes:
      - identifier: Terraform Destroy
    unified_job_template:
      name: Terraform // Web Demo Configure
      organization:
        name: Autodotes
        type: organization
      type: job_template
  - identifier: Terraform Destroy
    job_tags: remove
    unified_job_template:
      name: Terraform // Web Demo Deploy
      organization:
        name: Autodotes
        type: organization
      type: job_template
```

## The Outcome

The Ansible configuration playbook will template a landing page based on host variables for the respective Azure VM. Below is an example view from one of my runs:

![Terraform Create Web Demo Site](../.attachments/az_create_web_demo_site.png)

## Service Now Integration

The playbooks can track progress in ServiceNow using the [ITSM collection](https://galaxy.ansible.com/ibm/ibm_itsm) (or a compatible ServiceNow/ITSM integration). This is optional: all ITSM-related tasks and variables are gated so the playbooks run normally when no ServiceNow context is provided.

### Input variables (from workflow or a prior job)

These are typically provided by a workflow survey or by an earlier job that creates/updates ServiceNow records:

| Variable | Purpose |
| --- | --- |
| `sc_task_created` | Dict keyed by host; each value has `number` and `sys_id` of the ServiceNow task to update (e.g. from an ITSM “create task” step). |
| `request_item_sys_id` | `sys_id` of the parent Request Item (RITM) to update when the full deployment is complete. |
| `aap_host` | AAP controller hostname (optional; used in work notes links). |
| `awx_workflow_job_id` | Workflow job ID (optional; used in work notes links). |
| `awx_job_id` | Playbook job ID (optional; used in work notes links). |

### Terraform variable

| Variable | Purpose |
| --- | --- |
| `sc_task` | Task number passed into Terraform from `sc_task_created[inventory_hostname]['number']` (or `N/A`). Exposed in [outputs](./outputs.tf) so the task number is stored with the deployment. |

### Tasks and stats used for tracking

**In [tf_ops.yml](./ansible/tf_ops.yml):**

- **Terraform apply/destroy**  
  Passes `sc_task` (and AAP URLs) into Terraform so state/outputs reference the ServiceNow task.
- **After a successful apply** (when `sc_task_created` is defined):
  - **Prep stats for task update** – Builds payload to update the existing task: work notes (workflow/job links + VM details JSON), `close_notes`, and `state: 3` (Closed complete).
  - **Set stats for task update** – Exposes `update_sc_task_sys_id` and `update_sc_task_data_overrides` for a downstream job to perform the task update via the ITSM collection.
  - **Set stats for web server task create** – Exposes `create_sc_task_data_overrides` (one entry per VM) so a downstream job can create a child ServiceNow task per host for the “Configure Web Servers” step (e.g. `short_description`: “Ansible initiating configuration of &lt;vm_name&gt;”).

**In [configure_web.yml](./ansible/configure_web.yml):**

- **Per-host task update** (when `sc_task_created` is defined):  
  For each configured web host, sets `update_sc_task_sys_id` and `update_sc_task_data_overrides` with work notes (workflow/job/site links), `close_notes`, and `state: 3` so the per-VM task can be closed.
- **Request item update** (on localhost):  
  Sets `update_ritm_sys_id` and `update_ritm_data_overrides` with work notes (workflow link), `close_notes`, and `state: 3` so the parent RITM can be closed when AAP + Terraform deployment is complete.

### Stat keys consumed by ITSM update jobs

A workflow or convergence play that uses the ITSM collection should read these stats (set by the playbooks above) and call the appropriate modules to create/update records:

| Stat key | Used to |
| --- | --- |
| `update_sc_task_sys_id` | Identify which ServiceNow task (by `sys_id`) to update. |
| `update_sc_task_data_overrides` | Payload (work_notes, close_notes, state, etc.) for that task update. |
| `create_sc_task_data_overrides` | Payloads for creating one child task per VM (e.g. for “Configure Web Servers”). |
| `update_ritm_sys_id` | Identify which Request Item to update. |
| `update_ritm_data_overrides` | Payload for closing/updating the RITM. |

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