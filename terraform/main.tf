module "resource_group" {
  source = "git::https://github.com/mbrickerd/terraform-azure-modules.git//modules/resource-group?ref=1307e0391fb15460a1a7c8c2a50144f7ebe8de8f"

  name        = var.name
  environment = var.environment
  location    = var.location

  tags = local.tags
}
