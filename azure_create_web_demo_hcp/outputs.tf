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

output "azure_web_demo_vm_details" {
  description = "List of VM details suitable for populating a CMDB."
  value = [
    for i in range(length(azurerm_linux_virtual_machine.web_demo)) : {
      name                = azurerm_linux_virtual_machine.web_demo[i].name
      id                  = azurerm_linux_virtual_machine.web_demo[i].id
      resource_group      = azurerm_resource_group.web_demo.name
      location            = azurerm_linux_virtual_machine.web_demo[i].location
      size                = azurerm_linux_virtual_machine.web_demo[i].size
      computer_name      = azurerm_linux_virtual_machine.web_demo[i].computer_name
      admin_username     = azurerm_linux_virtual_machine.web_demo[i].admin_username
      os_type            = "Linux"
      os_publisher       = azurerm_linux_virtual_machine.web_demo[i].source_image_reference[0].publisher
      os_offer           = azurerm_linux_virtual_machine.web_demo[i].source_image_reference[0].offer
      os_sku             = azurerm_linux_virtual_machine.web_demo[i].source_image_reference[0].sku
      os_version         = azurerm_linux_virtual_machine.web_demo[i].source_image_reference[0].version
      private_ip_address = azurerm_network_interface.web_demo[i].private_ip_address
      public_ip_address  = azurerm_public_ip.web_demo[i].ip_address
      subscription_id    = data.azurerm_client_config.current.subscription_id
      tenant_id          = data.azurerm_client_config.current.tenant_id
      network_interface_id = azurerm_network_interface.web_demo[i].id
      os_disk = {
        name = azurerm_linux_virtual_machine.web_demo[i].os_disk[0].name
        size_gb = azurerm_linux_virtual_machine.web_demo[i].os_disk[0].disk_size_gb
        storage_account_type = azurerm_linux_virtual_machine.web_demo[i].os_disk[0].storage_account_type
      }
      data_disk = {
        id       = azurerm_managed_disk.web_demo[i].id
        name     = azurerm_managed_disk.web_demo[i].name
        size_gb  = azurerm_managed_disk.web_demo[i].disk_size_gb
        storage_account_type = azurerm_managed_disk.web_demo[i].storage_account_type
      }
      tags = azurerm_linux_virtual_machine.web_demo[i].tags
    }
  ]
}
