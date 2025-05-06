module "key_vault" {
  source = "git::https://github.com/mbrickerd/terraform-azure-modules.git//modules/key-vault?ref=0fdadfdea745314ba1a97b61232946332266d734"

  resource_group_name = module.resource_group.name
  name                = var.name
  location            = var.location
  tenant_id           = data.azurerm_client_config.current.tenant_id

  sku_name                      = "standard"
  public_network_access_enabled = true
  network_acls = {
    bypass                     = "AzureServices"
    default_action             = "Allow"
    ip_rules                   = []
    virtual_network_subnet_ids = [module.keyvault_subnet.id, module.aks_subnet.id]
  }

  soft_delete_retention_days  = 90
  purge_protection_enabled    = true
  enabled_for_disk_encryption = true

  private_endpoint_enabled   = true
  private_endpoint_subnet_id = module.keyvault_subnet.id
  private_dns_zone_id        = azurerm_private_dns_zone.keyvault.id

  rbac_assignments = [
    {
      principal_id         = azuread_service_principal.prism_terraform_env.id
      role_definition_name = "Key Vault Secrets Officer"
    },
    {
      principal_id         = azuread_service_principal.prism_terraform_env.id
      role_definition_name = "Key Vault Administrator"
    }
  ]

  tags = local.tags
}

module "key_vault_secrets" {
  source = "git::https://github.com/mbrickerd/terraform-azure-modules.git//modules/key-vault-secret?ref=3142ff88ecc04fa09b7f6a15aad93909764675d6"

  for_each = local.secrets

  key_vault_id    = module.key_vault.id
  name            = each.key
  content         = each.value.content
  content_type    = each.value.content_type
  expiration_date = try(each.value.expiration_date, null)
  tags            = try(each.value.tags, null)
}
