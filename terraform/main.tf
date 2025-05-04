module "app_registration" {
  source = "git::https://github.com/mbrickerd/terraform-azure-modules.git//modules/app-registration?ref=bf4876f9a6db8f130a27e3baa4b3c1c0400c305b"

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
  repository    = "prism-infra"
  variable_name = "AZURE_SUBSCRIPTION_ID"
  value         = data.azurerm_client_config.current.subscription_id

  lifecycle {
    ignore_changes = [value]
  }
}

resource "github_actions_variable" "azure_tenant_id" {
  repository    = "prism-infra"
  variable_name = "AZURE_TENANT_ID"
  value         = data.azurerm_client_config.current.tenant_id

  lifecycle {
    ignore_changes = [value]
  }
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
  source = "git::https://github.com/mbrickerd/terraform-azure-modules.git//modules/resource-group?ref=bf4876f9a6db8f130a27e3baa4b3c1c0400c305b"

  name        = var.name
  environment = var.environment
  location    = var.location

  tags = {
    managed_by_terraform = true
    environment          = var.environment
  }
}

resource "azurerm_role_assignment" "resource_group_contributor" {
  scope                = module.resource_group.id
  role_definition_name = "Contributor"
  principal_id         = azuread_service_principal.prism_terraform_env.id
}

module "storage_account" {
  source = "git::https://github.com/mbrickerd/terraform-azure-modules.git//modules/storage-account?ref=bf4876f9a6db8f130a27e3baa4b3c1c0400c305b"

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

  tags = {
    managed_by_terraform = true
    environment          = var.environment
  }
}

resource "azurerm_role_assignment" "storage_blob_contributor" {
  scope                = module.storage_account.id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = azuread_service_principal.prism_terraform_env.id
}

module "tfstate_storage_container" {
  source = "git::https://github.com/mbrickerd/terraform-azure-modules.git//modules/storage-container?ref=bf4876f9a6db8f130a27e3baa4b3c1c0400c305b"

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
  source = "git::https://github.com/mbrickerd/terraform-azure-modules.git//modules/storage-container?ref=bf4876f9a6db8f130a27e3baa4b3c1c0400c305b"

  name               = "sensors"
  storage_account_id = module.storage_account.id
  metadata           = {}
}
