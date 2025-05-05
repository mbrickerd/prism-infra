module "app_registration" {
  source = "git::https://github.com/mbrickerd/terraform-azure-modules.git//modules/app-registration?ref=1307e0391fb15460a1a7c8c2a50144f7ebe8de8f"

  display_name = "mb-prism-sensor-clustering-${var.environment}"
}

resource "azuread_service_principal" "prism_terraform_env" {
  client_id = module.app_registration.client_id
  tags      = ["terraform", var.environment, "prism-cluster"]
}

resource "github_actions_variable" "azure_client_id" {
  repository    = "prism-infra"
  variable_name = "AZURE_CLIENT_ID_${upper(var.environment)}"
  value         = module.app_registration.client_id
}

resource "github_actions_variable" "azure_subscription_id" {
  count = local.create_shared_variables ? 1 : 0

  repository    = "prism-infra"
  variable_name = "AZURE_SUBSCRIPTION_ID"
  value         = data.azurerm_client_config.current.subscription_id
}

resource "github_actions_variable" "azure_tenant_id" {
  count = local.create_shared_variables ? 1 : 0

  repository    = "prism-infra"
  variable_name = "AZURE_TENANT_ID"
  value         = data.azurerm_client_config.current.tenant_id
}

resource "azuread_application_federated_identity_credential" "github_infra_main" {
  application_id = module.app_registration.id
  display_name   = "github-infra-main"
  description    = "GitHub Actions workflow identity for deployments from main branch in the ${var.environment} infrastructure repository."
  audiences      = ["api://AzureADTokenExchange"]
  issuer         = "https://token.actions.githubusercontent.com"
  subject        = "repo:mbrickerd/prism-infra:ref:refs/heads/main"
}

resource "azuread_application_federated_identity_credential" "github_infra_pr" {
  application_id = module.app_registration.id
  display_name   = "github-infra-pr"
  description    = "GitHub Actions workflow identity for validation of pull requests in the ${var.environment} infrastructure repository."
  audiences      = ["api://AzureADTokenExchange"]
  issuer         = "https://token.actions.githubusercontent.com"
  subject        = "repo:mbrickerd/prism-infra:pull_request"
}

resource "azuread_application_federated_identity_credential" "github_infra_env" {
  application_id = module.app_registration.id
  display_name   = "github-infra-${var.environment}"
  description    = "GitHub Actions workflow identity for deployments to the ${var.environment} environment in the infrastructure repository."
  audiences      = ["api://AzureADTokenExchange"]
  issuer         = "https://token.actions.githubusercontent.com"
  subject        = "repo:mbrickerd/prism-infra:environment:${var.environment}"
}

module "resource_group" {
  source = "git::https://github.com/mbrickerd/terraform-azure-modules.git//modules/resource-group?ref=1307e0391fb15460a1a7c8c2a50144f7ebe8de8f"

  name        = var.name
  environment = var.environment
  location    = var.location

  tags = local.tags
}

resource "azurerm_role_assignment" "resource_group_contributor" {
  scope                = module.resource_group.id
  role_definition_name = "Contributor"
  principal_id         = azuread_service_principal.prism_terraform_env.id
}

module "storage_account" {
  source = "git::https://github.com/mbrickerd/terraform-azure-modules.git//modules/storage-account?ref=1307e0391fb15460a1a7c8c2a50144f7ebe8de8f"

  resource_group_name           = module.resource_group.name
  name                          = var.name
  environment                   = var.environment
  location                      = var.location
  public_network_access_enabled = true
  shared_access_key_enabled     = true
  allowed_copy_scope            = "AAD"
  network_rules = {
    default_action             = "Allow"
    bypass                     = ["AzureServices"]
    ip_rules                   = []
    virtual_network_subnet_ids = []
    private_link_access        = []
  }

  tags = local.tags
}

resource "azurerm_role_assignment" "storage_blob_contributor" {
  scope                = module.storage_account.id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = azuread_service_principal.prism_terraform_env.id
}

module "tfstate_storage_container" {
  source = "git::https://github.com/mbrickerd/terraform-azure-modules.git//modules/storage-container?ref=1307e0391fb15460a1a7c8c2a50144f7ebe8de8f"

  name               = "${var.environment}-tfstate"
  storage_account_id = data.azurerm_storage_account.bootstrap.id
  metadata           = {}
}

resource "azurerm_role_assignment" "bootstrap_storage_blob_data_contributor" {
  scope                = "${data.azurerm_storage_account.bootstrap.id}/blobServices/default/containers/tfstate"
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = azuread_service_principal.prism_terraform_env.id
}

resource "azurerm_role_assignment" "bootstrap_storage_reader" {
  scope                = data.azurerm_storage_account.bootstrap.id
  role_definition_name = "Reader"
  principal_id         = azuread_service_principal.prism_terraform_env.id
}

resource "azurerm_role_assignment" "bootstrap_storage_key_operator" {
  scope                = data.azurerm_storage_account.bootstrap.id
  role_definition_name = "Storage Account Key Operator Service Role"
  principal_id         = azuread_service_principal.prism_terraform_env.id
}

module "sensors_storage_container" {
  source = "git::https://github.com/mbrickerd/terraform-azure-modules.git//modules/storage-container?ref=1307e0391fb15460a1a7c8c2a50144f7ebe8de8f"

  name               = "sensors"
  storage_account_id = module.storage_account.id
  metadata           = {}
}

module "eventhub_namespace" {
  source = "git::https://github.com/mbrickerd/terraform-azure-modules.git//modules/eventhub-namespace?ref=1307e0391fb15460a1a7c8c2a50144f7ebe8de8f"

  resource_group_name          = module.resource_group.name
  name                         = var.name
  location                     = var.location
  sku                          = "Standard"
  capacity                     = 1
  local_authentication_enabled = true
  auto_inflate_enabled         = true
  maximum_throughput_units     = 3

  tags = local.tags
}

module "log_analytics" {
  source = "git::https://github.com/mbrickerd/terraform-azure-modules.git//modules/log-analytics?ref=1307e0391fb15460a1a7c8c2a50144f7ebe8de8f"

  resource_group_name       = module.resource_group.name
  name                      = var.name
  environment               = var.environment
  location                  = var.location
  retention_in_days         = 30
  enable_container_insights = true

  tags = local.tags
}

module "aks" {
  source = "git::https://github.com/mbrickerd/terraform-azure-modules.git//modules/kubernetes-cluster?ref=1307e0391fb15460a1a7c8c2a50144f7ebe8de8f"

  resource_group_name = module.resource_group.name
  name                = var.name
  environment         = var.environment
  location            = var.location
  kubernetes_version  = "1.31.7"
  tenant_id           = var.tenant_id

  default_node_pool_vm_size = "Standard_A2_v2"
  os_disk_size_gb           = 128
  auto_scaling_enabled      = true
  min_count                 = 2
  max_count                 = 5
  node_count                = null

  network_plugin      = "azure"
  network_plugin_mode = "overlay"
  pod_cidr            = "10.244.0.0/16"
  service_cidr        = "10.0.0.0/16"
  dns_service_ip      = "10.0.0.10"

  local_account_disabled            = true
  enable_key_vault_secrets_provider = true
  key_vault_rotation_enabled        = false
  key_vault_rotation_interval       = "2m"

  log_analytics_workspace_id = module.log_analytics.id
  enable_prometheus          = true
  enable_grafana             = true

  tags = local.tags
}

module "key_vault" {
  source = "git::https://github.com/mbrickerd/terraform-azure-modules.git//modules/key-vault?ref=ff110419534d29dd42faeed398d20d0bab93198e"

  resource_group_name = module.resource_group.name
  name                = var.name
  location            = var.location
  tenant_id           = data.azurerm_client_config.current.tenant_id

  sku_name = "standard"
  network_acls = {
    bypass                     = "AzureServices"
    default_action             = "Allow"
    ip_rules                   = []
    virtual_network_subnet_ids = []
  }

  soft_delete_retention_days = 90
  purge_protection_enabled   = false

  enabled_for_disk_encryption = true

  private_endpoint_enabled   = false
  private_endpoint_subnet_id = null
  private_dns_zone_id        = null

  tags = local.tags
}

resource "azurerm_role_assignment" "kv_secrets_officer" {
  scope                = module.key_vault.id
  role_definition_name = "Key Vault Secrets Officer"
  principal_id         = azuread_service_principal.prism_terraform_env.id
}

resource "azurerm_role_assignment" "kv_administrator" {
  scope                = module.key_vault.id
  role_definition_name = "Key Vault Administrator"
  principal_id         = azuread_service_principal.prism_terraform_env.id
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
