# -----------------------------------------------------------------------------
# 1. Azure resources (same as azure_create_web_demo_hcp)
# -----------------------------------------------------------------------------

resource "azurerm_resource_group" "web_demo" {
  name     = var.az_resource_group
  location = var.az_region
  tags     = var.web_tags_base
}

resource "azurerm_virtual_network" "web_demo" {
  name                = var.web_vnet_name
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.web_demo.location
  resource_group_name = azurerm_resource_group.web_demo.name
  tags                = var.web_tags_base
}

resource "azurerm_subnet" "web_demo" {
  name                 = var.web_subnet_name
  resource_group_name  = azurerm_resource_group.web_demo.name
  virtual_network_name = azurerm_virtual_network.web_demo.name
  address_prefixes     = ["10.0.2.0/24"]
}

resource "azurerm_network_security_group" "web_demo" {
  name                = var.web_nsg_name
  resource_group_name  = azurerm_resource_group.web_demo.name
  location             = azurerm_resource_group.web_demo.location
  tags                 = var.web_tags_base

  security_rule {
    name                       = "ssh"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_address_prefix      = "*"
    source_port_range          = "*"
    destination_address_prefix = "*"
    destination_port_range     = "22"
    description                = "allow ssh mgmt of vms"
  }

  security_rule {
    name                       = "https"
    priority                   = 101
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_address_prefix      = "*"
    source_port_range          = "*"
    destination_address_prefix = "*"
    destination_port_range     = "443"
    description                = "allow https traffic for web server"
  }

  security_rule {
    name                       = "http"
    priority                   = 102
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_address_prefix      = "*"
    source_port_range          = "*"
    destination_address_prefix = "*"
    destination_port_range     = "80"
    description                = "allow http traffic for web server"
  }
}

resource "azurerm_subnet_network_security_group_association" "web_demo" {
  subnet_id                 = azurerm_subnet.web_demo.id
  network_security_group_id = azurerm_network_security_group.web_demo.id
}

resource "azurerm_public_ip" "web_demo" {
  count                = 2
  name                 = "web-demo-pip-${count.index}"
  location             = azurerm_resource_group.web_demo.location
  resource_group_name  = azurerm_resource_group.web_demo.name
  allocation_method    = "Static"
  tags                 = var.web_tags_base
}

resource "azurerm_network_interface" "web_demo" {
  count               = 2
  name                = "${var.web_nic_name}${count.index}"
  location            = azurerm_resource_group.web_demo.location
  resource_group_name = azurerm_resource_group.web_demo.name
  tags                = var.web_tags_base

  ip_configuration {
    name                          = "web-demo-ip-configuration"
    subnet_id                     = azurerm_subnet.web_demo.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.web_demo[count.index].id
  }
}

resource "azurerm_ssh_public_key" "web_demo" {
  name                = var.web_demo_ssh_pubkey_name
  resource_group_name = azurerm_resource_group.web_demo.name
  location            = azurerm_resource_group.web_demo.location
  public_key          = var.web_demo_ssh_pubkey
  tags                = var.web_tags_base
}

resource "azurerm_linux_virtual_machine" "web_demo" {
  count                 = 2
  name                  = "${var.web_vm_name}${count.index}"
  location              = azurerm_resource_group.web_demo.location
  resource_group_name   = azurerm_resource_group.web_demo.name
  network_interface_ids = [azurerm_network_interface.web_demo[count.index].id]
  size                  = var.web_vm_size
  tags                  = var.web_tags_base

  source_image_reference {
    publisher = "RedHat"
    offer     = "RHEL"
    sku       = "810-gen2"
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
  tags                 = var.web_tags_base
}

resource "azurerm_virtual_machine_data_disk_attachment" "web_demo" {
  count              = 2
  managed_disk_id    = azurerm_managed_disk.web_demo[count.index].id
  virtual_machine_id = azurerm_linux_virtual_machine.web_demo[count.index].id
  lun                = "10"
  caching            = "ReadWrite"
}

# -----------------------------------------------------------------------------
# 2. AAP inventory, group, and hosts (certified ansible/aap provider)
# -----------------------------------------------------------------------------

data "aap_organization" "org" {
  name = var.aap_organization_name
}

resource "aap_inventory" "inventory" {
  name         = var.aap_inventory_name
  description  = "Web demo hosts created by Terraform from Azure VMs"
  organization = data.aap_organization.org.id
}

# Group name must match the playbook's hosts: target (tag_demo_web)
resource "aap_group" "inventory_group" {
  inventory_id = aap_inventory.inventory.id
  name         = "tf_group_web_demo"
  depends_on = [aap_inventory.inventory]
}

resource "aap_host" "web_hosts" {
  count        = 2
  inventory_id = aap_inventory.inventory.id
  name         = azurerm_linux_virtual_machine.web_demo[count.index].name
  groups       = [aap_group.inventory_group.id]
  variables = jsonencode({
    ansible_host       = azurerm_public_ip.web_demo[count.index].ip_address
    computer_name      = azurerm_linux_virtual_machine.web_demo[count.index].computer_name
    public_ip_address  = azurerm_public_ip.web_demo[count.index].ip_address
  })

  depends_on = [aap_inventory.inventory,aap_group.inventory_group]
}

# -----------------------------------------------------------------------------
# 3. Launch AAP job template to configure web servers
# -----------------------------------------------------------------------------

data "aap_job_template" "jt" {
  name              = var.aap_job_template_name
  organization_name  = var.aap_organization_name
}

# Job runs after Azure VMs and AAP hosts exist. Job template must have
# "Prompt on launch" for Inventory so this inventory_id is used.
resource "aap_job" "job" {
  job_template_id  = data.aap_job_template.jt.id
  extra_vars = jsonencode({
    _hosts = aap_group.inventory_group.name
  })
  depends_on = [aap_host.web_hosts]
}
