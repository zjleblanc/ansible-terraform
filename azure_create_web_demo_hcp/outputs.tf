# CMDB-oriented outputs for the created VMs (e.g. for Ansible inventory or config DB)

output "aap_job_url" {
  description = "URL of the Ansible Automation Platform job."
  value = var.aap_job_url
}

output "aap_workflow_url" {
  description = "URL of the Ansible Automation Platform workflow."
  value = var.aap_workflow_url
}

output "sc_task" {
  description = "Number of the ServiceNow task."
  value = var.sc_task
}

output "sn_configuration_items" {
  value = concat(
    # 1. Map Virtual Machines
    [
      for k, vm in azurerm_linux_virtual_machine.web_demo : {
        name           = vm.name
        sys_class_name = "cmdb_ci_linux_server"
        attributes = {
          correlation_id    = vm.id
          ip_address        = vm.private_ip_address
          location          = vm.location
          cost_center       = lookup(vm.tags, "cost-center", "")
          owned_by          = lookup(vm.tags, "owner", "")
          short_description = "Managed by Terraform: ${vm.computer_name}"
        }
      }
    ],
    # 2. Map Managed Disks
    [
      for k, disk in azurerm_managed_disk.web_demo : {
        name           = disk.name
        sys_class_name = "cmdb_ci_storage_volume"
        attributes = {
          correlation_id = disk.id
          size_bytes     = disk.disk_size_gb * 1024 * 1024 * 1024
          location       = disk.location
        }
      }
    ],
    # 3. Map Virtual Networks
    [
      {
        name           = azurerm_virtual_network.web_demo.name
        sys_class_name = "cmdb_ci_network"
        attributes = {
          correlation_id = azurerm_virtual_network.web_demo.id
          location       = azurerm_virtual_network.web_demo.location
        }
      }
    ]
  )
}

output "sn_ci_relationships" {
  value = flatten([
    # Map Disk to VM Relationships
    [
      for attachment in azurerm_virtual_machine_data_disk_attachment.web_demo : {
        parent = attachment.virtual_machine_id
        child  = attachment.managed_disk_id
        type   = "Provides storage for::Stored on"
      }
    ],

    # Map NIC to VM Relationships
    [
      for vm in azurerm_linux_virtual_machine.web_demo : [
        for nic_id in vm.network_interface_ids : {
          parent = vm.id
          child  = nic_id
          type   = "Inbound Connection::Outbound Connection"
        }
      ]
    ]
  ])
}