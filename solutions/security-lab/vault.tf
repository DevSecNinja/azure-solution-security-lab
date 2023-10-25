#
# Resource Group
#

resource "azurecaf_name" "rg_kv_generic" {
  name          = "kv_generic"
  resource_type = "azurerm_resource_group"
  prefixes      = []
  suffixes      = [local.project_shortname, "01"]
  clean_input   = true
}

resource "azurerm_resource_group" "rg_kv_generic" {
  name     = azurecaf_name.rg_kv_generic.result
  location = local.config.generic.regions.primaryRegion.name
  tags     = local.tags
}

#
# Generic Key Vault
#

resource "azurecaf_name" "generic_kv" {
  name          = "generic"
  resource_type = "azurerm_key_vault"
  prefixes      = []
  suffixes      = [local.config.generic.org.root_id, "01"]
  clean_input   = true
}

resource "azurerm_key_vault" "generic_kv" {
  name                       = azurecaf_name.generic_kv.result
  resource_group_name        = azurerm_resource_group.rg_kv_generic.name
  location                   = azurerm_resource_group.rg_kv_generic.location
  tenant_id                  = local.config.generic.org.tenant_id
  soft_delete_retention_days = 14
  purge_protection_enabled   = false
  tags                       = local.tags

  sku_name = "standard"

  access_policy {
    tenant_id = local.config.generic.org.tenant_id
    object_id = "f8719d08-2e15-4aec-8a81-313c4fbdf6a5" # Terraform account used to deploy this lab
    secret_permissions = [
      "Get",
      "Set",
      "Delete",
      "Purge"
    ]
  }
}