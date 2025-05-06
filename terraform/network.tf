module "vnet" {
  source = "git::https://github.com/mbrickerd/terraform-azure-modules.git//modules/virtual-network?ref=0fdadfdea745314ba1a97b61232946332266d734"

  resource_group_name = module.resource_group.name
  name                = var.name
  environment         = var.environment
  location            = var.location
  address_space       = ["10.1.0.0/16"]
  subnet              = []
  encryption = {
    enforcement = "AllowUnencrypted"
  }
  flow_timeout_in_minutes = 10

  tags = local.tags
}

module "storage_subnet" {
  source = "git::https://github.com/mbrickerd/terraform-azure-modules.git//modules/subnet?ref=0fdadfdea745314ba1a97b61232946332266d734"

  resource_group_name               = module.resource_group.name
  name                              = "subnet-storage-${var.name}-${var.environment}"
  environment                       = var.environment
  virtual_network_name              = module.vnet.name
  address_prefixes                  = ["10.1.3.0/24"]
  service_endpoints                 = ["Microsoft.Storage"]
  private_endpoint_network_policies = "Disabled"
}

module "aks_subnet" {
  source = "git::https://github.com/mbrickerd/terraform-azure-modules.git//modules/subnet?ref=0fdadfdea745314ba1a97b61232946332266d734"

  resource_group_name  = module.resource_group.name
  name                 = "subnet-aks-${var.name}-${var.environment}"
  environment          = var.environment
  virtual_network_name = module.vnet.name
  address_prefixes     = ["10.1.2.0/24"]
  service_endpoints    = ["Microsoft.KeyVault"]
}

module "keyvault_subnet" {
  source = "git::https://github.com/mbrickerd/terraform-azure-modules.git//modules/subnet?ref=0fdadfdea745314ba1a97b61232946332266d734"

  resource_group_name               = module.resource_group.name
  name                              = "subnet-kv-${var.name}-${var.environment}"
  environment                       = var.environment
  virtual_network_name              = module.vnet.name
  address_prefixes                  = ["10.1.1.0/24"]
  service_endpoints                 = ["Microsoft.KeyVault"]
  private_endpoint_network_policies = "Disabled"
}

resource "azurerm_private_dns_zone" "storage" {
  resource_group_name = module.resource_group.name
  name                = "privatelink.blob.core.windows.net"

  tags = local.tags
}

resource "azurerm_private_dns_zone" "keyvault" {
  resource_group_name = module.resource_group.name
  name                = "privatelink.vaultcore.azure.net"

  tags = local.tags
}

resource "azurerm_private_dns_zone_virtual_network_link" "storage" {
  resource_group_name   = module.resource_group.name
  name                  = "dns-link-storage-${var.name}-${var.environment}"
  private_dns_zone_name = azurerm_private_dns_zone.storage.name
  virtual_network_id    = module.vnet.id

  tags = local.tags
}

resource "azurerm_private_dns_zone_virtual_network_link" "keyvault" {
  resource_group_name   = module.resource_group.name
  name                  = "dns-link-kv-${var.name}-${var.environment}"
  private_dns_zone_name = azurerm_private_dns_zone.keyvault.name
  virtual_network_id    = module.vnet.id

  tags = local.tags
}
