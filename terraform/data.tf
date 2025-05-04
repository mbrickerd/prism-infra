data "azurerm_client_config" "current" {}

data "azurerm_resource_group" "bootstrap" {
  name = "rg-prism-cluster-mgmt"
}

data "azurerm_storage_account" "bootstrap" {
  name                = "saprismclustermgmt"
  resource_group_name = data.azurerm_resource_group.bootstrap.name
}
