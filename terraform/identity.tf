resource "azurerm_user_assigned_identity" "aks_keyvault" {
  name                = "mi-keyvault-${var.name}-${var.environment}"
  resource_group_name = module.resource_group.name
  location            = var.location

  tags = local.tags
}

resource "azurerm_user_assigned_identity" "aks_storage" {
  name                = "mi-storage-${var.name}-${var.environment}"
  resource_group_name = module.resource_group.name
  location            = var.location

  tags = local.tags
}

resource "azurerm_user_assigned_identity" "aks_eventhub" {
  name                = "mi-eventhub-${var.name}-${var.environment}"
  resource_group_name = module.resource_group.name
  location            = var.location

  tags = local.tags
}
