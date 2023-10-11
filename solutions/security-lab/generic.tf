#
# Random Password
#

# TODO: Store VM DC password in Key Vault

resource "random_password" "vm_dc_password" {
  length           = 24
  special          = true
  override_special = "!#$%&*-_=+:?"
}
