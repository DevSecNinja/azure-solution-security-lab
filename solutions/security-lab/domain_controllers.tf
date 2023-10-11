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


#
# Domain Controllers
#

resource "azurecaf_name" "vm_dc" {
  name          = "dc"
  resource_type = "azurerm_windows_virtual_machine"
  prefixes      = []
  suffixes      = [local.project_shortname, "01"]
  clean_input   = true
}

module "domain_controllers" {
  source                   = "Azure/compute/azurerm"
  resource_group_name      = azurerm_resource_group.rg_dc.name
  is_windows_image         = true
  vm_hostname              = azurecaf_name.vm_dc.name
  admin_password           = random_password.vm_dc_password.result
  vm_os_simple             = "WindowsServer"
  vnet_subnet_id           = module.network.vnet_subnets[0]
  name_template_vm_windows = "$${vm_hostname}-vmw-$${host_number}"

  data_sa_type = "Premium_LRS"
  extra_disks = [
    {
      size = 50
      name = "data"
    }
  ]

  depends_on           = [azurerm_resource_group.rg_dc]
  tracing_tags_enabled = true
  tags                 = local.tags
}

#
# Shutdown Policy
#

resource "azurerm_dev_test_global_vm_shutdown_schedule" "vm_dc" {
  count = length(module.domain_controllers.vm_ids)

  virtual_machine_id = module.domain_controllers.vm_ids[count.index]
  location           = azurerm_resource_group.rg_dc.location
  enabled            = "true"

  daily_recurrence_time = "2000"
  timezone              = "W. Europe Standard Time"
  notification_settings {
    enabled = false
  }
}
