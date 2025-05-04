plugin "terraform" {
  enabled = true
  preset  = "recommended"
}

plugin "azurerm" {
  enabled    = true
  version    = "0.28.0"
  source     = "github.com/terraform-linters/tflint-ruleset-azurerm"
  deep_check = false
}

rule "terraform_required_providers" {
  enabled = false
}

rule "terraform_required_version" {
  enabled = false
}

rule "terraform_module_pinned_source" {
  enabled = false
}
