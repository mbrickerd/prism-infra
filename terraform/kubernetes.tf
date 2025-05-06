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

resource "kubernetes_namespace" "sensors" {
  metadata {
    name = "sensors"
  }
}

resource "kubernetes_service_account" "sensors" {
  metadata {
    name      = "sa-aks-${var.name}-${var.environment}"
    namespace = kubernetes_namespace.sensors.metadata[0].name

    annotations = {
      "azure.workload.identity/client-id" = module.app_registration.client_id
    }
  }

  automount_service_account_token = true
}

resource "kubernetes_service_account" "keyvault" {
  metadata {
    name      = "sa-kv-${var.name}-${var.environment}"
    namespace = kubernetes_namespace.sensors.metadata[0].name

    annotations = {
      "azure.workload.identity/client-id" = azurerm_user_assigned_identity.aks_keyvault.client_id
    }
  }
}

resource "kubernetes_service_account" "storage" {
  metadata {
    name      = "sa-storage-${var.name}-${var.environment}"
    namespace = kubernetes_namespace.sensors.metadata[0].name

    annotations = {
      "azure.workload.identity/client-id" = azurerm_user_assigned_identity.aks_storage.client_id
    }
  }
}

resource "kubernetes_service_account" "eventhub" {
  metadata {
    name      = "sa-eventhub-${var.name}-${var.environment}"
    namespace = kubernetes_namespace.sensors.metadata[0].name

    annotations = {
      "azure.workload.identity/client-id" = azurerm_user_assigned_identity.aks_eventhub.client_id
    }
  }
}

resource "kubernetes_role" "namespace_admin" {
  metadata {
    name      = "namespace-admin"
    namespace = kubernetes_namespace.sensors.metadata[0].name
  }

  # Keep the specific rule for resourcequotas and endpoints
  rule {
    api_groups = [""]
    resources  = ["resourcequotas", "endpoints"]
    verbs      = ["list", "get", "watch"]
  }

  # Split the wildcard rules into more specific ones
  rule {
    api_groups = [""]
    resources = [
      "pods",
      "pods/log",
      "services",
      "secrets",
      "configmaps",
      "persistentvolumeclaims"
    ]
    verbs = ["get", "list", "watch", "create", "update", "patch", "delete"]
  }

  rule {
    api_groups = ["apps"]
    resources = [
      "deployments",
      "statefulsets",
      "replicasets"
    ]
    verbs = ["get", "list", "watch", "create", "update", "patch", "delete"]
  }

  rule {
    api_groups = ["batch"]
    resources = [
      "jobs",
      "cronjobs"
    ]
    verbs = ["get", "list", "watch", "create", "update", "patch", "delete"]
  }

  rule {
    api_groups = ["networking.k8s.io"]
    resources  = ["ingresses"]
    verbs      = ["get", "list", "watch", "create", "update", "patch", "delete"]
  }

  rule {
    api_groups = ["cert-manager.io"]
    resources  = ["certificates", "issuers"]
    verbs      = ["get", "list", "watch", "create", "update", "patch", "delete"]
  }

  # For specific functionality that requires exec
  rule {
    api_groups = [""]
    resources  = ["pods/exec", "pods/portforward", "pods/ephemeralcontainers"]
    verbs      = ["get", "create", "update"]
  }

  # For monitoring
  rule {
    api_groups = ["monitoring.coreos.com"]
    resources  = ["prometheuses", "alertmanagers", "servicemonitors", "prometheusrules"]
    verbs      = ["get", "list", "watch"]
  }

  # For pod identity
  rule {
    api_groups = ["aadpodidentity.k8s.io"]
    resources  = ["*"]
    verbs      = ["list", "get", "watch"]
  }
}

resource "kubernetes_role_binding" "sensors_admin_binding" {
  metadata {
    name      = "sensors-admin-binding"
    namespace = kubernetes_namespace.sensors.metadata[0].name
  }

  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "Role"
    name      = kubernetes_role.namespace_admin.metadata[0].name
  }

  subject {
    kind      = "ServiceAccount"
    name      = kubernetes_service_account.sensors.metadata[0].name
    namespace = kubernetes_namespace.sensors.metadata[0].name
  }
}
