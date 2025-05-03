module "app_registration" {
  source = "git::https://github.com/mbrickerd/terraform-azure-modules.git//modules/app-registration?ref=bf4876f9a6db8f130a27e3baa4b3c1c0400c305b"

  display_name = "mb-prism-sensor-clustering-${var.environment}"
}

resource "azuread_service_principal" "prism_terraform_env" {
  client_id = module.app_registration.client_id
  tags      = ["terraform", var.environment, "prism-cluster"]
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

module "resource_group" {
  source = "git::https://github.com/mbrickerd/terraform-azure-modules.git//modules/resource-group?ref=bf4876f9a6db8f130a27e3baa4b3c1c0400c305b"

  name        = var.name
  environment = var.environment
  location    = var.location
}

resource "azurerm_role_assignment" "resource_group_contributor" {
  scope                = "/subscriptions/${data.azurerm_client_config.current.subscription_id}/resourceGroups/${module.resource_group.name}"
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
}

resource "azurerm_role_assignment" "storage_blob_contributor" {
  scope                = module.storage_account.id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = azuread_service_principal.prism_terraform_env.id
}

module "messages_storage_container" {
  source = "git::https://github.com/mbrickerd/terraform-azure-modules.git//modules/storage-container?ref=bf4876f9a6db8f130a27e3baa4b3c1c0400c305b"

  name               = "messages"
  storage_account_id = module.storage_account.id
  metadata           = {}
}
