# tf_state_cmdb

Ansible role that reads **Terraform state resources** (`tf_state_resources`) and produces **ServiceNow-oriented CMDB payloads**: configuration items (CIs) and relationship rows. Results are published with **`ansible.builtin.set_stats`** so a controller workflow, job template chain, or callback can push them into ServiceNow (for example via table APIs or `zjleblanc.servicenow.records`).

---

## Usage

Include the role after you have a list of resource objects from Terraform state (typically `values.root_module.resources` from hosted JSON state).

```yaml
- name: Map Terraform state to ServiceNow CMDB structures
  ansible.builtin.include_role:
    name: tf_state_cmdb
  vars:
    tf_state_resources: "{{ (lookup('file', path_to_state_json) | from_json)['values']['root_module']['resources'] | default([]) }}"
```

A concrete example lives in [../../tfe_run.yml](../../tfe_run.yml), which downloads state and passes `tf_state_resources` into this role.

**Optional:** Override list variables in [defaults/main.yml](./defaults/main.yml) (which Terraform types and subelement specs to process) via play vars, `include_role` `vars`, group_vars, or a vars file. **CI templates, direct relationship templates, and subelement specs** live as YAML under **`files/ci_maps/`**, **`files/rel_maps/`**, and **`files/subelement_maps/`** in the role; extend the role by adding or editing those files (or fork the role), not by supplying a single merged `sn_manage_resource_maps` dict in vars (Ansible’s merge/templating walks all keys and breaks **`{{ _resource }}`** / **`{{ _item }}`** scoping).

---

## Role variables

### Required (caller-supplied)

| Variable | Description |
| -------- | ----------- |
| **`tf_state_resources`** | List of Terraform state **resource** dicts (same shape as `root_module.resources` in Terraform’s JSON state). Each item is expected to include at least `type`, `address`, and `values` (and any nested fields your Jinja templates reference). |

### Defined in `defaults/main.yml` (override to customize)

| Variable | Description |
| -------- | ----------- |
| **`sn_manage_resource_map_types`** | List of Terraform resource **type** strings (e.g. `azurerm_virtual_network`). For each entry, the role loads **`files/ci_maps/<type>.yml`** via `include_vars` when building the CI work queue. That file defines one CI template: `name`, `sys_class_name`, and `other` (dict of extra CI fields). String values are Jinja evaluated later with **`_resource`** set to the current state resource. |
| **`sn_manage_relationship_map_types`** | List of Terraform **types** that originate **direct** relationship rows. For each entry, the role loads **`files/rel_maps/<type>.yml`**, which contains a top-level **`relationships:`** list. Each list item has `parent`, `parent_type`, `type`, `child`, `child_type` (Jinja with **`_resource`**). Optional **`relationship_when`**: if present, must be truthy for that row to be emitted. |
| **`sn_manage_relationship_subelement_spec_names`** | Basenames (without `.yml`) of specs under **`files/subelement_maps/`**. Each file is one **subelement** spec: `resource_type`, `subelements` (path for Ansible’s `subelements` filter), optional `skip_missing`, and **`relationships:`**. Rows use the same *logical* shape as direct maps (`parent`, `parent_type`, `type`, `child`, `child_type`), but **`parent` and `child` are [JMESPath](https://jmespath.org/) strings** resolved with **`vars \| json_query(...)`** in [tasks/main.yml](./tasks/main.yml) (not Jinja `{{ ... }}` like **`files/rel_maps/`**). Paths are evaluated against playbook **`vars`** where **`_resource`** is the Terraform resource and **`_item`** is the current inner value from `subelements` (see below). |

Templates are **not** kept in a single large dict in `defaults`/`vars`: Ansible merges role variables and can template across sibling keys, which leaves **`{{ _resource }}`** / **`{{ _item }}`** unresolved or empty. **`!unsafe`** is also unsuitable here because it stops later Jinja passes, so output stats would still contain literal template text. Per-type files loaded per iteration avoid both problems.

### Defined in `vars/main.yml` (role-internal convenience lists)

These are **derived lists** from `tf_state_resources` for common Azure types. They exist so defaults (and your overrides) can write shorter Jinja, e.g. subnet parent VNet resolution.

| Variable | Terraform `type` filtered |
| -------- | ------------------------- |
| `tf_state_cmdb_rgs` | `azurerm_resource_group` |
| `tf_state_cmdb_vnets` | `azurerm_virtual_network` |
| `tf_state_cmdb_subnets` | `azurerm_subnet` |
| `tf_state_cmdb_vms` | `azurerm_linux_virtual_machine` |
| `tf_state_cmdb_nics` | `azurerm_network_interface` |
| `tf_state_cmdb_disks` | `azurerm_managed_disk` |
| `tf_state_cmdb_disk_attachments` | `azurerm_virtual_machine_data_disk_attachment` |

**Note:** `vars/main.yml` has higher precedence than `defaults/main.yml`. To add a new filtered list for use in your map templates, you can either extend `vars/main.yml` in a fork, or keep logic inline in your overrides using `tf_state_resources | selectattr('type', 'equalto', '...')`.

### Set during role execution (`set_fact`)

| Variable | Purpose |
| -------- | ------- |
| **`tf_state_cmdb_subnet_parent_vnet_by_address`** | Map from subnet resource `address` → parent VNet resource object, built before CIs/relationships so subnet templates can pull tags/location from the parent VNet. |

Internal lists such as **`_ci_work_queue`**, **`_rel_work_queue`**, and **`_sub_rel_work_queue`** are implementation details used while building the final stats.

---

## From maps to ServiceNow data structures

This section describes the **processing pipeline** implemented in [tasks/main.yml](./tasks/main.yml) and [tasks/build_ci_configuration_item.yml](./tasks/build_ci_configuration_item.yml).

### 1. Subnet → parent VNet index

For each subnet in `tf_state_cmdb_subnets`, the role finds the matching VNet in `tf_state_cmdb_vnets` (same resource group and VNet name as in the subnet’s `values`) and stores it in **`tf_state_cmdb_subnet_parent_vnet_by_address`**, keyed by the subnet’s **`address`**. This powers subnet CI fields and conditional subnet→VNet relationships when the parent exists.

### 2. Configuration items (`sn_manage_resources`)

1. **Initialize** empty lists **`_sn_configuration_items`** and **`_sn_ci_relationships`**.
2. **Flatten the CI work queue** (`_ci_work_queue`): for each string in **`sn_manage_resource_map_types`**, `include_vars` loads **`files/ci_maps/<type>.yml`** into a short-lived var, then for every `tf_state_resources` element whose **`type`** equals that string, append **`{ tpl: <loaded template>, resource: <state resource> }`**. Resources are sorted by **`address`** for stable ordering.
3. **For each** queue entry (via `include_tasks` so inner steps stay grouped):
   - Set **`_resource`** and **`_ci_tpl`** from the queue item.
   - Reset **`_ci_other_resolved`**.
   - For each key in `_ci_tpl.other`, resolve the template string (with `_resource` available) and accumulate into **`_ci_other_resolved`**.
   - Append one CI dict to **`_sn_configuration_items`**:

     ```yaml
     name: "<resolved _ci_tpl.name>"
     sys_class_name: "<resolved _ci_tpl.sys_class_name>"
     other: "<dict _ci_other_resolved>"
     ```

The per-type files under **`files/ci_maps/`** define *what* to emit per Terraform type; the role always produces the same **output shape**: `name`, `sys_class_name`, and `other` suitable for downstream upsert logic.

### 3. Direct relationships (`files/rel_maps/`)

1. **Flatten** (`_rel_work_queue`): for each type in **`sn_manage_relationship_map_types`**, load **`files/rel_maps/<type>.yml`**, then for each matching resource and each entry under **`relationships:`**, append **`{ resource, rel }`**.
2. **For each** row, set **`_resource`** and **`_rel_item`**, build a normalized **`_rel_row`** (`parent`, `parent_type`, `type`, `child`, `child_type`), and append to **`_sn_ci_relationships`** when **`_rel_item.relationship_when`** is not defined or evaluates true.

### 4. Subelement relationships (`files/subelement_maps/`)

1. **Flatten** (`_sub_rel_work_queue`) in [tasks/accumulate_sub_rel_one_spec.yml](./tasks/accumulate_sub_rel_one_spec.yml): for each basename in **`sn_manage_relationship_subelement_spec_names`**, `include_vars` loads **`files/subelement_maps/<name>.yml`** as **`sm_spec`**. Resources are filtered to **`sm_spec.resource_type`**, sorted by **`address`**, then passed through Ansible’s **`subelements(sm_spec.subelements, skip_missing)`**, which yields **`(resource, item)`** pairs—one **`item`** per entry along the nested path (for example each string in **`values.network_interface_ids`**). For each pair and each dict under **`sm_spec.relationships`**, the task appends **`{ resource, item, rel }`** to the queue. The **`rel`** dict is stored as loaded from YAML; **`rel.parent`** and **`rel.child`** remain **query strings**, not rendered CI ids yet.

2. **Resolve ids in** [tasks/main.yml](./tasks/main.yml): the task *Append subelement relationships from subelement work queue* loops the queue and sets **`_resource`**, **`_item`**, and **`_rel_item`** from each entry. It builds **`_rel_row`** so that:
   - **`parent`** = `{{ vars | json_query(_rel_item.parent) }}`
   - **`child`** = `{{ vars | json_query(_rel_item.child) }}`
   - **`parent_type`**, **`type`**, **`child_type`** are taken verbatim from the spec (literals).

   Because **`json_query`** runs against **`vars`**, the spec should use dotted paths that start from those names (for example **`_resource.values.id`** for the VM’s Azure resource id, **`_item`** when the subelement is already a scalar id string). That produces the same **`parent` / `child`** string ids ServiceNow expects as direct relationship rows, but without embedding Jinja in the subelement YAML file. Each **`_rel_row`** is appended to **`_sn_ci_relationships`**.

### 5. Publish for downstream jobs

**`ansible.builtin.set_stats`** exposes:

| Stat key | Type | Content |
| -------- | ---- | ------- |
| **`sn_manage_resources`** | list | CI payloads: `name`, `sys_class_name`, `other`. |
| **`sn_manage_relationships`** | list | Relationship payloads: `parent`, `parent_type`, `type`, `child`, `child_type`. |

Downstream automation should treat **`parent` / `child`** values consistently with how CIs are keyed in ServiceNow (this role’s defaults use Azure resource IDs and synthetic datacenter keys such as `azure/<region>` where documented in the parent project README).

---

## Extending the role for more Terraform resource types

### Add or adjust configuration items

1. Choose the Terraform **`type`** string exactly as it appears in state (e.g. `azurerm_windows_virtual_machine`).
2. Add **`files/ci_maps/<type>.yml`** (same shape as existing CI files) with:
   - **`name`**, **`sys_class_name`**: Jinja strings using **`_resource`** (e.g. `_resource['values']['name']`, `_resource['address']`).
   - **`other`**: arbitrary keys your ServiceNow integration expects; each value is a Jinja string templated with **`_resource`** in scope.
3. Append that **`type`** string to **`sn_manage_resource_map_types`** in **`defaults/main.yml`** or override the list in your play.
4. If you need **another resource type** for lookups (peers, parents), you can:
   - Reference **`tf_state_resources`** with `selectattr` / `json_query` in your Jinja, or
   - Add a filtered list in **`vars/main.yml`** and use it from your templates, or
   - Add a **`set_fact`** task in [tasks/main.yml](./tasks/main.yml) *before* the CI queue build (same pattern as the subnet→VNet index).

Re-test with a state file that contains the new `type` so `values` paths match your templates.

### Add or adjust direct relationships

1. Add or edit **`files/rel_maps/<type>.yml`** for the Terraform **`type`** that should *originate* the relationship rows (top-level **`relationships:`** list).
2. Each list item is a dict with **`parent`**, **`parent_type`**, **`type`**, **`child`**, **`child_type`** (all templated with **`_resource`**).
3. Ensure **`sn_manage_relationship_map_types`** includes that **`type`** (defaults or play override).
4. Use **`relationship_when`** when a row should only exist under some condition (see **`azurerm_subnet`** rel map: only relate subnet to VNet when the parent VNet was resolved).

### Add or adjust subelement-driven relationships

Use **`files/subelement_maps/<spec>.yml`** plus an entry in **`sn_manage_relationship_subelement_spec_names`** when the relationship is driven by **each entry in a list** (or nested structure) under `values`, not only scalar fields on the resource:

1. Create a new YAML file with **`resource_type`**, **`subelements`** (path passed to Ansible’s [`subelements`](https://docs.ansible.com/ansible/latest/collections/ansible/builtin/subelements_filter.html) filter), optional **`skip_missing`**, and **`relationships:`**.
2. In each relationship dict, set **`parent_type`**, **`type`**, and **`child_type`** to the literal strings your integration expects. Set **`parent`** and **`child`** to **JMESPath expressions** (no surrounding `{{ }}`) that **`json_query`** can evaluate against **`vars`** after the main task sets **`_resource`** and **`_item`**. Examples: **`_resource.values.id`**, **`_item`**, or deeper paths if **`_item`** is a dict. Do not copy the Jinja style used under **`files/rel_maps/`** for **`parent`/`child`** here—those direct rows are resolved differently.
3. Add the file’s basename (without `.yml`) to **`sn_manage_relationship_subelement_spec_names`**.
4. Confirm the **`subelements`** path exists in your provider’s state shape for that resource type. A working reference is [files/subelement_maps/azurerm_linux_virtual_machine_network_interfaces.yml](./files/subelement_maps/azurerm_linux_virtual_machine_network_interfaces.yml).

### Precedence and testing tips

- Put **environment-specific** or **workspace-specific** overrides in play vars or a dedicated vars file included by the play; keep **`defaults/main.yml`** as the shared baseline.
- After changes, run the role against a real **`tf_state_resources`** list and inspect **`hostvars['localhost']['ansible_stats']['data']`** (or the equivalent your environment uses for job stats) for **`sn_manage_resources`** and **`sn_manage_relationships`**.
- This README’s **usage** and demo wiring refer to [../../tfe_run.yml](../../tfe_run.yml) under **`azure_create_web_demo_tfe_aap/`**. Other playbooks in the repository (including ad-hoc or local test playbooks at the repo root) are **not** documented here.

For more context on how this demo wires state download and stats consumers, see the parent [README.md](../../../README.md) section *Mapping Terraform state to ServiceNow CMDB*.
