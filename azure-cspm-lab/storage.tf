resource "azurerm_storage_account" "misconfigured_public" {
  name                     = "tylercspmlabmis0730"
  resource_group_name      = azurerm_resource_group.main.name
  location                 = azurerm_resource_group.main.location
  account_tier             = "Standard"
  account_replication_type = "LRS"

  allow_nested_items_to_be_public = false

  tags = {
    Project = "cspm-lab"
    Purpose = "intentional-misconfig"
  }
}

resource "azurerm_storage_container" "misconfigured_public" {
  name                  = "public-container"
  storage_account_id    = azurerm_storage_account.misconfigured_public.id
  container_access_type = "private"
}

resource "azurerm_storage_account" "secure" {
  name                     = "tylercspmlabsec0730"
  resource_group_name      = azurerm_resource_group.main.name
  location                 = azurerm_resource_group.main.location
  account_tier             = "Standard"
  account_replication_type = "LRS"

  allow_nested_items_to_be_public = false
  min_tls_version                 = "TLS1_2"

  tags = {
    Project = "cspm-lab"
  }
}