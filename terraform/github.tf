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
