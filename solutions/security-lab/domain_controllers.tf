#
# Resource Group
#

resource "azurecaf_name" "rg_dc" {
  name          = "dc"
  resource_type = "azurerm_resource_group"
  prefixes      = []
  suffixes      = [local.project_shortname, "01"]
  clean_input   = true
}

resource "azurerm_resource_group" "rg_dc" {
  name     = azurecaf_name.rg_dc.result
  location = local.config.generic.regions.primaryRegion.name
  tags     = local.tags
}
