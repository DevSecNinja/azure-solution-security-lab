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

resource "azurecaf_name" "vnet" {
  resource_type = "azurerm_virtual_network"
  prefixes      = []
  suffixes      = [local.project_shortname, "01"]
  clean_input   = true
}

module "network" {
  source  = "Azure/network/azurerm"
  version = "5.3.0"

  vnet_name           = azurecaf_name.vnet.result
  resource_group_name = azurerm_resource_group.rg_vnet.name
  address_spaces      = local.subnets
  subnet_prefixes     = local.subnets
  subnet_names        = ["tier-0", "tier-1"]

  depends_on           = [azurerm_resource_group.rg_vnet]
  tracing_tags_enabled = true
  tags                 = local.tags
  use_for_each         = true
}
