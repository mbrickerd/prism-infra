locals {
  create_shared_variables = var.environment == "dev"

  secrets = {
    "storage-connection-string" = {
      name         = "storage-connection-string"
      content      = module.storage_account.primary_connection_string
      content_type = "connection-string"
    },
    "storage-account-key" = {
      content      = module.storage_account.primary_access_key
      content_type = "account-key"
    },
    "eventhub-connection-string" = {
      content      = module.eventhub_namespace.default_primary_connection_string
      content_type = "connection-string"
    }
  }

  tags = merge(var.tags, {
    managed_by_terraform = true
    environment          = var.environment
    project              = "prism-cluster"
  })
}
