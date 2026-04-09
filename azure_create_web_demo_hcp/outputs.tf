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
    # Map location (datacenter)
    [
      {
        name           = azurerm_resource_group.web_demo.location
        sys_class_name = "cmdb_ci_azure_datacenter"
        other = {
          correlation_id        = "azure/${lower(azurerm_resource_group.web_demo.location)}"
          correlation_display   = "aap.terraform.io"
          short_description     = "azure region: ${lower(azurerm_resource_group.web_demo.location)}"
        }
      }
    ],

    # Map Virtual Network
    [
      {
        name           = azurerm_virtual_network.web_demo.name
        sys_class_name = "cmdb_ci_vpc"
        other = {
          correlation_id = azurerm_virtual_network.web_demo.id
          location              = azurerm_virtual_network.web_demo.location
          cost_center           = lookup(azurerm_virtual_network.web_demo.tags, "cost-center", "")
          owned_by              = lookup(azurerm_virtual_network.web_demo.tags, "owner", "")
          environment           = lookup(azurerm_virtual_network.web_demo.tags, "environment", "")
          short_description     = "Managed by Terraform"
        }
      }
    ],

    # Map Subnet
    [
      {
        name           = azurerm_subnet.web_demo.name
        sys_class_name = "cmdb_ci_subnet"
        other = {
          correlation_id = azurerm_subnet.web_demo.id
          correlation_display = "aap.terraform.io"
          location       = azurerm_virtual_network.web_demo.location
          cost_center           = lookup(azurerm_virtual_network.web_demo.tags, "cost-center", "")
          owned_by              = lookup(azurerm_virtual_network.web_demo.tags, "owner", "")
          environment           = lookup(azurerm_virtual_network.web_demo.tags, "environment", "")
          short_description     = "Managed by Terraform"
        }
      }
    ],

    # Map Virtual Machines
    [
      for k, vm in azurerm_linux_virtual_machine.web_demo : {
        name           = vm.name
        sys_class_name = "cmdb_ci_vm_instance"
        other = {
          correlation_id        = vm.id
          correlation_display   = "aap.terraform.io"
          os_name               = vm.source_image_reference[0]["offer"]
          os_version            = vm.source_image_reference[0]["version"]
          disk_space            = vm.os_disk[0].disk_size_gb * 1024 * 1024 * 1024
          ip_address            = vm.public_ip_address
          location              = vm.location
          cost_center           = lookup(vm.tags, "cost-center", "")
          owned_by              = lookup(vm.tags, "owner", "")
          environment           = lookup(vm.tags, "environment", "")
          short_description     = "Managed by Terraform"
        }
      }
    ],

    # Map Network Interfaces
    [
      for k, nic in azurerm_network_interface.web_demo : {
        name           = nic.name
        sys_class_name = "cmdb_ci_nic"
        other = {
          correlation_id        = nic.id
          correlation_display   = "aap.terraform.io"
          ip_address            = nic.private_ip_address
          mac_address           = nic.mac_address
          location              = nic.location
          cost_center           = lookup(nic.tags, "cost-center", "")
          owned_by              = lookup(nic.tags, "owner", "")
          environment           = lookup(nic.tags, "environment", "")
          short_description     = "Managed by Terraform"
        }
      }
    ],

    # Map Managed Disks
    [
      for k, disk in azurerm_managed_disk.web_demo : {
        name           = disk.name
        sys_class_name = "cmdb_ci_cloud_storage_volume"
        other = {
          correlation_id        = disk.id
          correlation_display   = "aap.terraform.io"
          size_bytes            = disk.disk_size_gb * 1024 * 1024 * 1024
          location              = disk.location
          cost_center           = lookup(disk.tags, "cost-center", "")
          owned_by              = lookup(disk.tags, "owner", "")
          environment           = lookup(disk.tags, "environment", "")
          short_description     = "Managed by Terraform"
        }
      }
    ]
  )
}

output "sn_ci_relationships" {
  # type must exist in cmdb_rel_type table
  # {parent descriptor}::{child descriptor}

  value = flatten([
    # Map VNet to Datacenter
    [
      {
        parent = azurerm_virtual_network.web_demo.id
        parent_type = "cmdb_ci_vpc"
        child = "azure/${lower(azurerm_resource_group.web_demo.location)}"
        child_type = "cmdb_ci_azure_datacenter"
        type = "Located in::Houses"
      }
    ],

    # Map Subnet to VNet Relationships
    [
      {
        parent = azurerm_subnet.web_demo.id
        parent_type = "cmdb_ci_subnet"
        child = azurerm_virtual_network.web_demo.id
        child_type = "cmdb_ci_vpc"
        type = "Located in::Houses"
      }
    ],

    # Map Disk to VM Relationships
    [
      for attachment in azurerm_virtual_machine_data_disk_attachment.web_demo : {
        parent  = attachment.managed_disk_id
        parent_type = "cmdb_ci_cloud_storage_volume"
        child = attachment.virtual_machine_id
        child_type = "cmdb_ci_vm_instance"
        type   = "Provides storage for::Stored on"
      }
    ],

    # Map NIC to VM Relationships
    [
      for k, nic in azurerm_network_interface.web_demo : {
        parent = nic.id
        parent_type = "cmdb_ci_nic"
        child = nic.virtual_machine_id
        child_type = "cmdb_ci_vm_instance"
        type   = "IP Connection::IP Connection"
      }
    ],

    # Map NIC to Subnet Relationships
    [
      for k, nic in azurerm_network_interface.web_demo : [
        for ip_config in nic.ip_configuration : {
          parent = nic.id
          parent_type = "cmdb_ci_nic"
          child = ip_config.subnet_id
          child_type = "cmdb_ci_subnet"
          type   = "Connects to::Connected by"
        }
      ]
    ],
  ])
}