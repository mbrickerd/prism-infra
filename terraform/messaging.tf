module "eventhub_namespace" {
  source = "git::https://github.com/mbrickerd/terraform-azure-modules.git//modules/eventhub-namespace?ref=1307e0391fb15460a1a7c8c2a50144f7ebe8de8f"

  resource_group_name          = module.resource_group.name
  name                         = var.name
  location                     = var.location
  sku                          = "Standard"
  capacity                     = 1
  local_authentication_enabled = true
  auto_inflate_enabled         = true
  maximum_throughput_units     = 3

  tags = local.tags
}
