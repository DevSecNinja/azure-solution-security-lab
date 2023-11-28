#
# Resource Group
#

resource "azurecaf_name" "rg_vm_mde" {
  name          = "mde"
  resource_type = "azurerm_resource_group"
  prefixes      = []
  suffixes      = [local.project_shortname, "01"]
  clean_input   = true
}

resource "azurerm_resource_group" "rg_vm_mde" {
  name     = azurecaf_name.rg_vm_mde.result
  location = local.config.generic.regions.primaryRegion.name
  tags     = local.tags
}


#
# Defender for Endpoint Test VM
#

resource "azurecaf_name" "vm_mde" {
  name          = "mde"
  resource_type = "azurerm_windows_virtual_machine"
  prefixes      = []
  suffixes      = [local.project_shortname, "01"]
  clean_input   = true
}

resource "random_password" "vm_mde_password" {
  length           = 24
  special          = true
  override_special = "!#$%&*-_=+:?"
}

resource "azurerm_key_vault_secret" "vm_mde_password" {
  name         = "vm-mde-password"
  value        = random_password.vm_mde_password.result
  key_vault_id = azurerm_key_vault.generic_kv.id
  content_type = "Virtual Machine ${azurecaf_name.vm_mde.name} Local Admin Password"
}

module "defender_for_endpoint_vms" {
  source  = "Azure/compute/azurerm"
  version = "5.3.0"

  resource_group_name      = azurerm_resource_group.rg_vm_mde.name
  vm_hostname              = azurecaf_name.vm_mde.name
  admin_username           = local.config.compute.virtualMachines.windows.settings.osProfile.adminUsername
  admin_password           = random_password.vm_mde_password.result
  vm_os_offer              = "Windows-11"
  vm_os_publisher          = "MicrosoftWindowsDesktop"
  vm_os_sku                = "win11-22h2-ent"
  vm_os_version            = "latest"
  is_windows_image         = true
  vnet_subnet_id           = module.network.vnet_subnets[2]
  name_template_vm_windows = "$${vm_hostname}-vmw-$${host_number}"

  delete_os_disk_on_termination    = true
  delete_data_disks_on_termination = true
  data_sa_type                     = "Premium_LRS"
  extra_disks = [
    {
      size = 50
      name = "data"
    }
  ]

  depends_on           = [azurerm_resource_group.rg_vm_mde]
  tracing_tags_enabled = true
  tags                 = local.tags
}

#
# Shutdown Policy
#

resource "azurerm_dev_test_global_vm_shutdown_schedule" "vm_mde" {
  count = length(module.defender_for_endpoint_vms.vm_ids)

  virtual_machine_id = module.defender_for_endpoint_vms.vm_ids[count.index]
  location           = azurerm_resource_group.rg_vm_mde.location
  enabled            = "true"

  daily_recurrence_time = "2000"
  timezone              = "W. Europe Standard Time"
  notification_settings {
    enabled = false
  }
}
