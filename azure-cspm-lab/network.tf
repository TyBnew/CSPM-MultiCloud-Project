resource "azurerm_virtual_network" "main" {
  name                = "cspm-lab-vnet"
  address_space       = ["10.1.0.0/16"]
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name

  tags = {
    Project = "cspm-lab"
  }
}

resource "azurerm_subnet" "main" {
  name                 = "cspm-lab-subnet"
  resource_group_name  = azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = ["10.1.1.0/24"]
}

resource "azurerm_network_security_group" "open_ssh" {
  name                = "cspm-lab-open-nsg"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name

  security_rule {
    name                       = "AllowSSHFromAnywhere"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "YOUR_IP_ADD/32"
    destination_address_prefix = "*"
  }

  tags = {
    Project = "cspm-lab"
    Purpose = "intentional-misconfig"
  }
}

resource "azurerm_network_security_group" "scoped" {
  name                = "cspm-lab-scoped-nsg"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name

  security_rule {
    name                       = "AllowSSHFromMyIP"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "YOUR_IP_ADD/32"
    destination_address_prefix = "*"
  }

  tags = {
    Project = "cspm-lab"
  }
}