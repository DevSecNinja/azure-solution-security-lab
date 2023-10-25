terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 3.29.1"
    }

    azuread = {
      source  = "hashicorp/azuread"
      version = "~> 2.44.1"
    }

    azurecaf = {
      source  = "aztfmod/azurecaf"
      version = "2.0.0-preview3"
    }

    random = {
      source  = "hashicorp/random"
      version = "3.5.1"
    }
  }

  cloud {
    organization = "ravensberg"

    workspaces {
      name = "AzureEnvironment_Solutions_SecurityLab"
    }
  }
}

locals {
  # Read the config files
  config_files = fileset(path.module, "../../generic/json/config/*.json")
  config = { for query_file in local.config_files :
    replace(basename(query_file), ".json", "") => jsondecode(file(query_file))
  }

  # Tags
  tags = merge(local.config.generic.tags, {
    terraformWorkspace = "AzureEnvironment_Solutions_SecurityLab"
    "owner.name"       = local.config.generic.org.owner.name
    "owner.email"      = local.config.generic.org.owner.email
  })

  project_shortname = "seclab"
  subnets           = ["172.16.20.0/24", "172.16.21.0/24"]
}
