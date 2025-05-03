<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.4.2 |
| <a name="requirement_azuread"></a> [azuread](#requirement\_azuread) | ~> 2.47.0 |
| <a name="requirement_azurerm"></a> [azurerm](#requirement\_azurerm) | ~> 4.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_azuread"></a> [azuread](#provider\_azuread) | 2.47.0 |
| <a name="provider_azurerm"></a> [azurerm](#provider\_azurerm) | 4.27.0 |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_app_registration"></a> [app\_registration](#module\_app\_registration) | git::https://github.com/mbrickerd/terraform-azure-modules.git//modules/app-registration | bf4876f9a6db8f130a27e3baa4b3c1c0400c305b |
| <a name="module_messages_storage_container"></a> [messages\_storage\_container](#module\_messages\_storage\_container) | git::https://github.com/mbrickerd/terraform-azure-modules.git//modules/storage-container | bf4876f9a6db8f130a27e3baa4b3c1c0400c305b |
| <a name="module_resource_group"></a> [resource\_group](#module\_resource\_group) | git::https://github.com/mbrickerd/terraform-azure-modules.git//modules/resource-group | bf4876f9a6db8f130a27e3baa4b3c1c0400c305b |
| <a name="module_storage_account"></a> [storage\_account](#module\_storage\_account) | git::https://github.com/mbrickerd/terraform-azure-modules.git//modules/storage-account | bf4876f9a6db8f130a27e3baa4b3c1c0400c305b |

## Resources

| Name | Type |
|------|------|
| [azuread_application_federated_identity_credential.github_infra_main](https://registry.terraform.io/providers/hashicorp/azuread/latest/docs/resources/application_federated_identity_credential) | resource |
| [azuread_application_federated_identity_credential.github_infra_pr](https://registry.terraform.io/providers/hashicorp/azuread/latest/docs/resources/application_federated_identity_credential) | resource |
| [azuread_service_principal.prism_terraform_env](https://registry.terraform.io/providers/hashicorp/azuread/latest/docs/resources/service_principal) | resource |
| [azurerm_role_assignment.resource_group_contributor](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/role_assignment) | resource |
| [azurerm_role_assignment.storage_blob_contributor](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/role_assignment) | resource |
| [azurerm_client_config.current](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/client_config) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_environment"></a> [environment](#input\_environment) | Specifies the environment the resource group belongs to. | `string` | `"dev"` | no |
| <a name="input_location"></a> [location](#input\_location) | The Azure Region where the Resource Group should exist. Defaults to `westeurope`. | `string` | `"westeurope"` | no |
| <a name="input_name"></a> [name](#input\_name) | The base name that will be used in the resource group naming convention. | `string` | `"prism-cluster"` | no |

## Outputs

No outputs.
<!-- END_TF_DOCS -->
