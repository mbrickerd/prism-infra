module "app_registration" {
  source = "git::https://github.com/mbrickerd/terraform-azure-modules.git//modules/app-registration?ref=1307e0391fb15460a1a7c8c2a50144f7ebe8de8f"

  display_name = "mb-prism-sensor-clustering-${var.environment}"
}

resource "azuread_service_principal" "prism_terraform_env" {
  client_id = module.app_registration.client_id
  tags      = ["terraform", var.environment, var.name]
}
