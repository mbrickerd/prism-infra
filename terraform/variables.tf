variable "name" {
  description = "The base name that will be used in the resource group naming convention."
  type        = string
  default     = "prism-cluster"
}

variable "environment" {
  description = "Specifies the environment the resource group belongs to."
  type        = string
  default     = "dev"

  validation {
    condition     = contains(["dev", "tst", "prd"], var.environment)
    error_message = "Invalid value for environment. Must be one of: `dev`, `tst`, `prd`."
  }
}

variable "location" {
  description = "The Azure Region where the Resource Group should exist. Defaults to `westeurope`."
  type        = string
  default     = "westeurope"
}

variable "tenant_id" {
  description = "The Azure Tenant ID."
  type        = string
}

variable "tags" {
  description = "A mapping of tags to add to all resources."
  type        = map(string)
  default     = {}
}
