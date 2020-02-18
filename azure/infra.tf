# Azure Infrastructure Resources

# Resource group containing all resources
resource "azurerm_resource_group" "rancher-quickstart" {
  name     = "${var.prefix}-rancher-quickstart"
  location = var.azure_location

  tags = {
    Creator = "rancher-quickstart"
  }
}

# Public IP of Rancher server
resource "azurerm_public_ip" "rancher-server-pip" {
  name                = "rancher-server-pip"
  location            = azurerm_resource_group.rancher-quickstart.location
  resource_group_name = azurerm_resource_group.rancher-quickstart.name
  allocation_method   = "Static"

  tags = {
    Creator = "rancher-quickstart"
  }
}

# Azure virtual network space for quickstart resources
resource "azurerm_virtual_network" "rancher-quickstart" {
  name                = "${var.prefix}-network"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.rancher-quickstart.location
  resource_group_name = azurerm_resource_group.rancher-quickstart.name

  tags = {
    Creator = "rancher-quickstart"
  }
}

# Azure internal subnet for quickstart resources
resource "azurerm_subnet" "rancher-quickstart-internal" {
  name                 = "rancher-quickstart-internal"
  resource_group_name  = azurerm_resource_group.rancher-quickstart.name
  virtual_network_name = azurerm_virtual_network.rancher-quickstart.name
  address_prefix       = "10.0.0.0/16"
}

# Azure network interface for quickstart resources
resource "azurerm_network_interface" "rancher-server-interface" {
  name                = "rancher-quickstart-interface"
  location            = azurerm_resource_group.rancher-quickstart.location
  resource_group_name = azurerm_resource_group.rancher-quickstart.name

  ip_configuration {
    name                          = "rancher_server_ip_config"
    subnet_id                     = azurerm_subnet.rancher-quickstart-internal.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.rancher-server-pip.id
  }

  tags = {
    Creator = "rancher-quickstart"
  }
}

# Azure virtual machine for creating a single node RKE cluster and installing the Rancher Server
resource "azurerm_virtual_machine" "rancher_server" {
  name                  = "${var.prefix}-rancher-server"
  location              = azurerm_resource_group.rancher-quickstart.location
  resource_group_name   = azurerm_resource_group.rancher-quickstart.name
  network_interface_ids = [azurerm_network_interface.rancher-server-interface.id]
  vm_size               = var.instance_type

  storage_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "18.04-LTS"
    version   = "latest"
  }
  storage_os_disk {
    name          = "rancher-quickstart-osdisk"
    create_option = "FromImage"
  }
  os_profile {
    computer_name  = "${var.prefix}-rancher-server"
    admin_username = local.node_username
    custom_data = templatefile("../cloud-common/files/userdata_rancher_server.template", {
      docker_version = var.docker_version
      username       = local.node_username
    })
  }
  os_profile_linux_config {
    disable_password_authentication = true
    ssh_keys {
      key_data = file("${var.ssh_key_file_name}.pub")
      path     = "/home/${local.node_username}/.ssh/authorized_keys"
    }
  }
  tags = {
    Creator = "rancher-quickstart"
  }

  provisioner "remote-exec" {
    inline = [
      "cloud-init status --wait"
    ]

    connection {
      type        = "ssh"
      host        = azurerm_public_ip.rancher-server-pip.ip_address
      user        = local.node_username
      private_key = file(var.ssh_key_file_name)
    }
  }
}

# Rancher resources
module "rancher_common" {
  source = "../rancher-common"

  node_public_ip         = azurerm_public_ip.rancher-server-pip.ip_address
  node_internal_ip       = azurerm_network_interface.rancher-server-interface.private_ip_address
  node_username          = local.node_username
  ssh_key_file_name      = var.ssh_key_file_name
  rke_kubernetes_version = var.rke_kubernetes_version

  cert_manager_version = var.cert_manager_version
  rancher_version      = var.rancher_version

  rancher_server_dns = "${replace(azurerm_public_ip.rancher-server-pip.ip_address, ".", "-")}.nip.io"
  admin_password     = var.rancher_server_admin_password

  workload_kubernetes_version = var.workload_kubernetes_version
  workload_cluster_name       = "quickstart-azure-custom"
}

# Public IP of quickstart node
resource "azurerm_public_ip" "quickstart-node-pip" {
  name                = "quickstart-node-pip"
  location            = azurerm_resource_group.rancher-quickstart.location
  resource_group_name = azurerm_resource_group.rancher-quickstart.name
  allocation_method   = "Static"

  tags = {
    Creator = "rancher-quickstart"
  }
}

# Azure network interface for quickstart resources
resource "azurerm_network_interface" "quickstart-node-interface" {
  name                = "quickstart-node-interface"
  location            = azurerm_resource_group.rancher-quickstart.location
  resource_group_name = azurerm_resource_group.rancher-quickstart.name

  ip_configuration {
    name                          = "rancher_server_ip_config"
    subnet_id                     = azurerm_subnet.rancher-quickstart-internal.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.quickstart-node-pip.id
  }

  tags = {
    Creator = "rancher-quickstart"
  }
}

# Azure virtual machine for creating a single node RKE cluster and installing the Rancher Server
resource "azurerm_virtual_machine" "quickstart-node" {
  name                  = "${var.prefix}-quickstart-node"
  location              = azurerm_resource_group.rancher-quickstart.location
  resource_group_name   = azurerm_resource_group.rancher-quickstart.name
  network_interface_ids = [azurerm_network_interface.quickstart-node-interface.id]
  vm_size               = var.instance_type

  storage_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "18.04-LTS"
    version   = "latest"
  }
  storage_os_disk {
    name          = "quickstart-node-osdisk"
    create_option = "FromImage"
  }
  os_profile {
    computer_name  = "${var.prefix}-quickstart-node"
    admin_username = local.node_username
    custom_data = templatefile("../cloud-common/files/userdata_rancher_server.template", {
      docker_version   = var.docker_version
      username         = local.node_username
      register_command = module.rancher_common.custom_cluster_command
    })
  }
  os_profile_linux_config {
    disable_password_authentication = true
    ssh_keys {
      key_data = file("${var.ssh_key_file_name}.pub")
      path     = "/home/${local.node_username}/.ssh/authorized_keys"
    }
  }
  tags = {
    Creator = "rancher-quickstart"
  }

  provisioner "remote-exec" {
    inline = [
      "cloud-init status --wait"
    ]

    connection {
      type        = "ssh"
      host        = azurerm_public_ip.quickstart-node-pip.ip_address
      user        = local.node_username
      private_key = file(var.ssh_key_file_name)
    }
  }
}
