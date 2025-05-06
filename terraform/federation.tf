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

resource "azurerm_federated_identity_credential" "workload_identity_keyvault" {
  name                = "workload-identity-kv-${var.environment}"
  resource_group_name = module.resource_group.name
  audience            = ["api://AzureADTokenExchange"]
  issuer              = module.aks.oidc_issuer_url
  parent_id           = azurerm_user_assigned_identity.aks_keyvault.id
  subject             = "system:serviceaccount:${kubernetes_namespace.sensors.metadata[0].name}:${kubernetes_service_account.keyvault.metadata[0].name}"
}

resource "azurerm_federated_identity_credential" "workload_identity_storage" {
  name                = "workload-identity-storage-${var.environment}"
  resource_group_name = module.resource_group.name
  audience            = ["api://AzureADTokenExchange"]
  issuer              = module.aks.oidc_issuer_url
  parent_id           = azurerm_user_assigned_identity.aks_storage.id
  subject             = "system:serviceaccount:${kubernetes_namespace.sensors.metadata[0].name}:${kubernetes_service_account.storage.metadata[0].name}"
}

resource "azurerm_federated_identity_credential" "workload_identity_eventhub" {
  name                = "workload-identity-eventhub-${var.environment}"
  resource_group_name = module.resource_group.name
  audience            = ["api://AzureADTokenExchange"]
  issuer              = module.aks.oidc_issuer_url
  parent_id           = azurerm_user_assigned_identity.aks_eventhub.id
  subject             = "system:serviceaccount:${kubernetes_namespace.sensors.metadata[0].name}:${kubernetes_service_account.eventhub.metadata[0].name}"
}
