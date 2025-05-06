module "storage_account" {
  source = "git::https://github.com/mbrickerd/terraform-azure-modules.git//modules/storage-account?ref=1307e0391fb15460a1a7c8c2a50144f7ebe8de8f"

  resource_group_name           = module.resource_group.name
  name                          = "${replace(var.name, "-", "")}${var.environment}"
  environment                   = var.environment
  location                      = var.location
  public_network_access_enabled = false
  shared_access_key_enabled     = false
  allowed_copy_scope            = "AAD"

  blob_properties = {
    versioning_enabled  = true
    change_feed_enabled = true
    delete_retention_policy = {
      days    = 7
      enabled = true
    }
    container_delete_retention_policy = {
      days    = 7
      enabled = true
    }
    restore_policy = {
      days    = 7
      enabled = true
    }
  }

  network_rules = {
    default_action             = "Deny"
    bypass                     = ["AzureServices"]
    ip_rules                   = []
    virtual_network_subnet_ids = [module.storage_subnet.id]
    private_link_access        = []
  }

  private_endpoint_enabled   = true
  private_endpoint_subnet_id = module.storage_subnet.id
  private_dns_zone_id        = azurerm_private_dns_zone.storage.id

  tags = local.tags
}

module "tfstate_storage_container" {
  source = "git::https://github.com/mbrickerd/terraform-azure-modules.git//modules/storage-container?ref=1307e0391fb15460a1a7c8c2a50144f7ebe8de8f"

  name               = "${var.environment}-tfstate"
  storage_account_id = data.azurerm_storage_account.bootstrap.id
  metadata           = {}
}

module "sensors_storage_container" {
  source = "git::https://github.com/mbrickerd/terraform-azure-modules.git//modules/storage-container?ref=1307e0391fb15460a1a7c8c2a50144f7ebe8de8f"

  name               = "sensors"
  storage_account_id = module.storage_account.id
  metadata           = {}
}
