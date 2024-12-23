resource "azurerm_resource_group" "web_demo" {
  name     = var.az_resource_group
  location = var.az_region
}

resource "azurerm_virtual_network" "web_demo" {
  name                = var.web_vnet_name
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.web_demo.location
  resource_group_name = azurerm_resource_group.web_demo.name
}

resource "azurerm_subnet" "web_demo" {
  name                 = var.web_subnet_name
  resource_group_name  = azurerm_resource_group.web_demo.name
  virtual_network_name = azurerm_virtual_network.web_demo.name
  address_prefixes     = ["10.0.2.0/24"]
}

resource "azurerm_public_ip" "web_demo" {
  name                = "web-demo-public-ip"
  location            = azurerm_resource_group.web_demo.location
  resource_group_name = azurerm_resource_group.web_demo.name
  allocation_method   = "Static"
}

resource "azurerm_lb" "web_demo" {
  name                = "web-demo-lb"
  location            = azurerm_resource_group.web_demo.location
  resource_group_name = azurerm_resource_group.web_demo.name

  frontend_ip_configuration {
    name                 = "web-demo-public-ip-assoc"
    public_ip_address_id = azurerm_public_ip.web_demo.id
  }
}

resource "azurerm_lb_backend_address_pool" "web_demo" {
  loadbalancer_id = azurerm_lb.web_demo.id
  name            = "web-demo-backend-addr-pool"
}

resource "azurerm_network_interface" "web_demo" {
  count               = 2
  name                = "${var.web_nic_name}${count.index}"
  location            = azurerm_resource_group.web_demo.location
  resource_group_name = azurerm_resource_group.web_demo.name

  ip_configuration {
    name                          = "web-demo-ip-configuration"
    subnet_id                     = azurerm_subnet.web_demo.id
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_availability_set" "web_demo" {
  name                         = "web-demo-avail-set"
  location                     = azurerm_resource_group.web_demo.location
  resource_group_name          = azurerm_resource_group.web_demo.name
  platform_fault_domain_count  = 2
  platform_update_domain_count = 2
  managed                      = true
}

resource "azurerm_ssh_public_key" "web_demo" {
  name                = var.web_demo_ssh_pubkey_name
  resource_group_name = azurerm_resource_group.web_demo.name
  location            = azurerm_resource_group.web_demo.location
  public_key          = file(var.web_demo_ssh_pubkey_local_path)
}

resource "azurerm_linux_virtual_machine" "web_demo" {
  count                 = 2
  name                  = "${var.web_vm_name}${count.index}"
  location              = azurerm_resource_group.web_demo.location
  availability_set_id   = azurerm_availability_set.web_demo.id
  resource_group_name   = azurerm_resource_group.web_demo.name
  network_interface_ids = [azurerm_network_interface.web_demo[count.index].id]
  size                  = "Standard_DS1_v2"

  source_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "16.04-LTS"
    version   = "latest"
  }

  admin_ssh_key {
    username   = var.web_demo_admin_username
    public_key = azurerm_ssh_public_key.web_demo.public_key
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
    name                 = "myosdisk${count.index}"
  }

  computer_name  = "${var.web_vm_name}${count.index}"
  admin_username = var.web_demo_admin_username
}

resource "azurerm_managed_disk" "web_demo" {
  count                = 2
  name                 = "datadisk_existing_${count.index}"
  location             = azurerm_resource_group.web_demo.location
  resource_group_name  = azurerm_resource_group.web_demo.name
  storage_account_type = "Standard_LRS"
  create_option        = "Empty"
  disk_size_gb         = "1024"
}

resource "azurerm_virtual_machine_data_disk_attachment" "web_demo" {
  count              = 2
  managed_disk_id    = azurerm_managed_disk.web_demo[count.index].id
  virtual_machine_id = azurerm_linux_virtual_machine.web_demo[count.index].id
  lun                = "10"
  caching            = "ReadWrite"
}