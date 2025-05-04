locals {
  create_shared_variables = var.environment == "dev"
  tags = merge(var.tags, {
    managed_by_terraform = true
    environment          = var.environment
    project              = "prism-cluster"
  })
}
