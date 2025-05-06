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

provider "kubernetes" {
  host                   = module.aks.host
  cluster_ca_certificate = base64decode(module.aks.cluster_ca_certificate)

  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    command     = "kubelogin"
    args = [
      "get-token",
      "--login", "azurecli",
      "--environment", "AzurePublicCloud",
      "--server-id", "6dae42f8-4368-4678-94ff-3960e28e3630"
    ]
  }
}
