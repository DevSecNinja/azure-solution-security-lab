#
# Resource Group
#

resource "azurecaf_name" "rg_vm_evilginx" {
  name          = "evilginx"
  resource_type = "azurerm_resource_group"
  prefixes      = []
  suffixes      = [local.project_shortname, "01"]
  clean_input   = true
}

resource "azurerm_resource_group" "rg_vm_evilginx" {
  name     = azurecaf_name.rg_vm_evilginx.result
  location = local.config.generic.regions.primaryRegion.name
  tags     = local.tags
}


#
# EvilGinx VM
#

resource "azurecaf_name" "vm_evilginx" {
  name          = "evilginx"
  resource_type = "azurerm_linux_virtual_machine"
  prefixes      = []
  suffixes      = [local.project_shortname, "01"]
  clean_input   = true
}

resource "random_password" "vm_evilginx_password" {
  length           = 24
  special          = true
  override_special = "!#$%&*-_=+:?"
}

resource "azurerm_key_vault_secret" "vm_evilginx_password" {
  name         = "vm-evilginx-password"
  value        = random_password.vm_evilginx_password.result
  key_vault_id = azurerm_key_vault.generic_kv.id
  content_type = "Virtual Machine ${azurecaf_name.vm_evilginx.name} Local Admin Password"
}

module "evilginx_vms" {
  source  = "Azure/compute/azurerm"
  version = "5.3.0"

  resource_group_name      = azurerm_resource_group.rg_vm_evilginx.name
  vm_hostname              = azurecaf_name.vm_evilginx.name
  admin_username           = local.config.compute.virtualMachines.linux.settings.osProfile.adminUsername
  admin_password           = random_password.vm_evilginx_password.result
  vm_os_offer              = "0001-com-ubuntu-server-jammy"
  vm_os_publisher          = "Canonical"
  vm_os_sku                = "22_04-lts"
  vm_os_version            = "latest"
  vnet_subnet_id           = module.evilginx_network.vnet_subnets[0]
  name_template_vm_linux   = "$${vm_hostname}-vml-$${host_number}"

  enable_ssh_key           = true
  ssh_key_values           = ["ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQDrGDCRDUvdnPFL9TGgICVWz9+qV21IYDpwf9P5tg73n5H0ZhA5Tn9ogo9VdzSrDMaXZ2/Ca1PQDEtjb7Q/6NDC9XQbL0DOsi0wyQiTcJopdZnyH6jYVwWUhJ1hXeEsmD9eVTfXwCelPzJpJU2um/w0UR5EhX6nI1Mh7koLjEycmXQLTZtkZlnJttdI63ka7xeDZbQSwbpaGpZkFlFTahjc7OTw1416jL9Ld3Mu2VF0Sg+MpJS4jUiJB7DaSI2RTQZSnMXTQe/uPy9Fj8npg8ti0kjnM4jf9hYYudq8nznnfSvC8tY44RL42Kh+K/H79tyfMTwPIOuww1hytSkJg7EAMv/o7zAZYyiQzOWIxWqlMFr1+8/laIkVnm9bP9tLN4mHdq4SBQA7woj6VWSKrplN13sOIDFXit726SMxEPFma87c1vUYdrvcZvDz7dSeYVvlz8Fv/pwuz6/KMShCVAtutvyHAdOfEwUHX/x/Bh9Yp6dnn2BdgNHyCnSbFc/J4fy7SMbWoi3DViTxsx/xycVW/EuoAehWmyWUO0+p5RYgauEmnBSDqAt6tIGy25+7p7ZPfZRSzG+02vNt+lWgcUcMehmfxy+ROOqNwvslrsKWp3r3cYszMMDhzrgVrxmiNeHO+tlrZGvO6euv1kNLCxCbQy7A7WCyyry4fBT2UBVYOw=="] # TOOD: To replace hardcoded key with GitHub Data Source

  delete_os_disk_on_termination    = true
  delete_data_disks_on_termination = true
  data_sa_type                     = "Premium_LRS"

  depends_on           = [azurerm_resource_group.rg_vm_evilginx]
  tracing_tags_enabled = true
  tags                 = local.tags
}

# SSH Public Keys
data "http" "github_public_ssh_keys" {
  url = "https://api.github.com/users/DevSecNinja/keys"

  request_headers = {
    Accept = "application/json"
  }
}

#
# Shutdown Policy
#

resource "azurerm_dev_test_global_vm_shutdown_schedule" "vm_evilginx" {
  count = length(module.evilginx_vms.vm_ids)

  virtual_machine_id = module.evilginx_vms.vm_ids[count.index]
  location           = azurerm_resource_group.rg_vm_evilginx.location
  enabled            = "true"

  daily_recurrence_time = "2000"
  timezone              = "W. Europe Standard Time"
  notification_settings {
    enabled = false
  }
}

#
# Network
#

module "evilginx_network" {
  source  = "Azure/network/azurerm"
  version = "5.3.0"
  use_for_each = true

  resource_group_name = azurerm_resource_group.rg_vm_evilginx.name
  subnet_prefixes     = ["192.168.250/24"]
  subnet_names        = ["primary"]

  depends_on = [azurerm_resource_group.rg_vm_evilginx]
}
