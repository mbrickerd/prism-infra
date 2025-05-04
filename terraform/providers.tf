provider "azurerm" {
  features {
    resource_group {
      prevent_deletion_if_contains_resources = false
    }
  }

  subscription_id = "1e702451-e125-465b-ba86-4343891daaa8"
}

provider "github" {
  owner = "mbrickerd"
}
