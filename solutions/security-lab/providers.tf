#
# Standard Provider
#


# Declare a standard provider block using your preferred configuration.
# This will target the "default" Subscription and be used for the deployment of all "Core resources".
provider "azurerm" {
  subscription_id = element(local.config.subscriptions.sandbox.subscriptions, index(local.config.subscriptions.sandbox.subscriptions.*.name, "jeanpaulv-sandbox-01")).id
  features {}
}

# Obtain client configuration from the un-aliased provider
data "azurerm_client_config" "core" {
  provider = azurerm
}
