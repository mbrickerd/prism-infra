resource "azurerm_role_assignment" "resource_group_contributor" {
  scope                = module.resource_group.id
  role_definition_name = "Contributor"
  principal_id         = azuread_service_principal.prism_terraform_env.id
}

resource "azurerm_role_assignment" "storage_blob_contributor" {
  scope                = module.storage_account.id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = azuread_service_principal.prism_terraform_env.id
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

resource "azurerm_role_assignment" "keyvault_identity_role" {
  scope                = module.key_vault.id
  role_definition_name = "Key Vault Secrets User"
  principal_id         = azurerm_user_assigned_identity.aks_keyvault.principal_id
}

resource "azurerm_role_assignment" "storage_identity_role" {
  scope                = module.storage_account.id
  role_definition_name = "Storage Blob Data Reader"
  principal_id         = azurerm_user_assigned_identity.aks_storage.principal_id
}

resource "azurerm_role_assignment" "eventhub_identity_role" {
  scope                = module.eventhub_namespace.id
  role_definition_name = "Azure Event Hubs Data Receiver"
  principal_id         = azurerm_user_assigned_identity.aks_eventhub.principal_id
}

resource "azurerm_role_assignment" "aks_rbac_admin" {
  scope                = module.aks.id
  role_definition_name = "Azure Kubernetes Service RBAC Admin"
  # principal_id         = azuread_service_principal.prism_terraform_env.id
  principal_id = data.azurerm_client_config.current.object_id
}

resource "azurerm_role_assignment" "aks_rbac_cluster_admin" {
  scope                = module.aks.id
  role_definition_name = "Azure Kubernetes Service RBAC Cluster Admin"
  principal_id         = data.azurerm_client_config.current.object_id # This is your user ID
}

resource "azurerm_role_assignment" "aks_cluster_admin" {
  scope                = module.aks.id
  role_definition_name = "Azure Kubernetes Service Cluster Admin Role"
  # principal_id         = azuread_service_principal.prism_terraform_env.id
  principal_id = data.azurerm_client_config.current.object_id
}

resource "azurerm_role_assignment" "aks_cluster_user" {
  scope                = module.aks.id
  role_definition_name = "Azure Kubernetes Service Cluster User Role"
  # principal_id         = azuread_service_principal.prism_terraform_env.id
  principal_id = data.azurerm_client_config.current.object_id
}
