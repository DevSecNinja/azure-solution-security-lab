#
# Resource Group
#

resource "azurecaf_name" "rg_vnet" {
  name          = "vnet"
  resource_type = "azurerm_resource_group"
  prefixes      = []
  suffixes      = [local.project_shortname, "01"]
  clean_input   = true
}

resource "azurerm_resource_group" "rg_vnet" {
  name     = azurecaf_name.rg_vnet.result
  location = local.config.generic.regions.primaryRegion.name
  tags     = local.tags
}


#
# Network
#

# This VNET setup is purely for demo purposes. In production, make sure to have separate VNETs and
# use the VNET peering functionality to bring them together with a firewall in the middle.

module "network" {
  source              = "Azure/network/azurerm"
  resource_group_name = azurerm_resource_group.rg_vnet.name
  subnet_prefixes     = ["172.16.20.0/24", "172.16.21.0/24"]
  subnet_names        = ["tier-0", "tier-1"]

  depends_on           = [azurerm_resource_group.rg_vnet]
  tracing_tags_enabled = true
  tags                 = local.tags
  use_for_each         = true
}
