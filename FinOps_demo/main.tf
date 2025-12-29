######################
# Configure Provider # 
######################
provider "azurerm" {
  features {}
  resource_provider_registrations = "none"
  subscription_id                 = "SUB_ID"
}
terraform {
  backend "azurerm" {
    subscription_id      = "SUBSCRIPTION_ID"
    resource_group_name  = "RG_IaCStateStorage01"
    storage_account_name = "iacstatedstorage01"
    container_name       = "iacstatedcontainer02"
    key                  = "Dev/dev-terraform.tfstate"
  }
}

###################
# Resource Groups #
###################
resource "azurerm_resource_group" "delo_d_webapp_we_rg" {
  name     = "DELO-D-WEBAPP-WE-RG"
  location = "westeurope"
  tags = {
    Environment = "Dev-Sub"
    Product     = "DeloWebApp"
    Owner       = "webapp@delo.com"
    Team        = "WebTeam"
    Region      = "WestEurope"
  }
}

resource "azurerm_resource_group" "delo_d_db_we_rg" {
  name     = "DELO-D-DB-WE-RG"
  location = "westeurope"
  tags = {
    Environment = "Dev-Sub"
    Product     = "DeloDatabase"
    Owner       = "db@delo.com"
    Team        = "DatabaseTeam"
    Region      = "WestEurope"
  }
}

resource "azurerm_resource_group" "delo_d_vm_we_rg" {
  name     = "DELO-D-VM-WE-RG"
  location = "westeurope"
  tags = {
    Environment = "Dev-Sub"
    Product     = "VMCompute"
    Owner       = "infra@delo.com"
    Team        = "InfraTeam"
    Region      = "WestEurope"
  }
}

###################
# WebApp Resource #
###################

# App Service Plan for the Web App
resource "azurerm_app_service_plan" "delo_d_webapp_plan_we" {
  name                = "webapp1001"
  location            = azurerm_resource_group.delo_d_webapp_we_rg.location
  resource_group_name = azurerm_resource_group.delo_d_webapp_we_rg.name
  kind                = "Linux"
  reserved            = true
  sku {
    tier = "Basic"
    size = "B1"
  }

  tags = {
    Environment = "Dev-Sub"
    Product     = "DeloWebApp"
    Owner       = "webapp@delo.com"
    Team        = "WebTeam"
    Region      = "WestEurope"
    Service     = "WebApp"
  }
}

# Simple Linux Web App
resource "azurerm_linux_web_app" "delo_d_webapp" {
  name                = "delo-d-webapp-sample"
  location            = azurerm_resource_group.delo_d_webapp_we_rg.location
  resource_group_name = azurerm_resource_group.delo_d_webapp_we_rg.name
  service_plan_id     = azurerm_app_service_plan.delo_d_webapp_plan_we.id
  site_config {}

  tags = {
    Environment = "Dev-Sub"
    Product     = "DeloWebApp"
    Owner       = "webapp@delo.com"
    Team        = "WebTeam"
    Region      = "WestEurope"
    Service     = "WebApp"
  }
}
#####################
# Database Resource #
#####################
resource "azurerm_cosmosdb_account" "delo_d_db_we" {
  name                       = "cosmosdb1001"
  resource_group_name        = azurerm_resource_group.delo_d_db_we_rg.name
  location                   = azurerm_resource_group.delo_d_db_we_rg.location
  offer_type                 = "Standard"
  kind                       = "GlobalDocumentDB"
  automatic_failover_enabled = false
  minimal_tls_version        = "Tls12"
  free_tier_enabled          = false

  consistency_policy {
    consistency_level       = "BoundedStaleness"
    max_interval_in_seconds = 300
    max_staleness_prefix    = 100000
  }
  geo_location {
    location          = "westeurope"
    failover_priority = 0
  }
  backup {
    type = "Continuous"
    tier = "Continuous7Days"
  }

  tags = {
    Environment = "Dev-Sub"
    Product     = "DeloDatabase"
    Owner       = "db@delo.com"
    Team        = "DatabaseTeam"
    Region      = "WestEurope"
    Service     = "CosmosDB"
  }
}

resource "azurerm_cosmosdb_sql_database" "sqldb_sample" {
  name                = "delo-d-sqldb-sample"
  resource_group_name = azurerm_resource_group.delo_d_db_we_rg.name
  account_name        = azurerm_cosmosdb_account.delo_d_db_we.name
}

# Cosmos DB SQL Containers - Template approach using for_each
resource "azurerm_cosmosdb_sql_container" "container_sample" {
  name                  = "delo-d-container-sample"
  resource_group_name   = azurerm_resource_group.delo_d_db_we_rg.name
  account_name          = azurerm_cosmosdb_account.delo_d_db_we.name
  database_name         = azurerm_cosmosdb_sql_database.sqldb_sample.name
  partition_key_paths   = ["/id"]
  partition_key_version = 2
  throughput            = 400
}


###############
# VM Resource #
###############

# Virtual network for VM
resource "azurerm_virtual_network" "delo_d_vm_vnet_we" {
  name                = "delo-d-vm-vnet"
  location            = azurerm_resource_group.delo_d_vm_we_rg.location
  resource_group_name = azurerm_resource_group.delo_d_vm_we_rg.name
  address_space       = ["10.1.0.0/16"]

  tags = {
    Environment = "Dev-Sub"
    Product     = "VMCompute"
    Owner       = "infra@delo.com"
    Team        = "InfraTeam"
    Region      = "WestEurope"
    Service     = "Network"
  }
}

resource "azurerm_subnet" "delo_d_vm_subnet_we" {
  name                 = "delo-d-vm-subnet"
  resource_group_name  = azurerm_resource_group.delo_d_vm_we_rg.name
  virtual_network_name = azurerm_virtual_network.delo_d_vm_vnet_we.name
  address_prefixes     = ["10.1.1.0/24"]
}

resource "azurerm_network_interface" "delo_d_vm_nic_we" {
  name                = "delo-d-nic-sample"
  location            = azurerm_resource_group.delo_d_vm_we_rg.location
  resource_group_name = azurerm_resource_group.delo_d_vm_we_rg.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.delo_d_vm_subnet_we.id
    private_ip_address_allocation = "Dynamic"
  }

  tags = {
    Environment = "Dev-Sub"
    Product     = "VMCompute"
    Owner       = "infra@delo.com"
    Team        = "InfraTeam"
    Region      = "WestEurope"
    Service     = "NIC"
  }
}

# Simple Linux VM
resource "azurerm_linux_virtual_machine" "delo_d_vm_we" {
  name                  = "vm1001"
  location              = azurerm_resource_group.delo_d_vm_we_rg.location
  resource_group_name   = azurerm_resource_group.delo_d_vm_we_rg.name
  network_interface_ids = [azurerm_network_interface.delo_d_vm_nic_we.id]
  size                  = "Standard_B1s"

  admin_username                  = "azureuser"
  disable_password_authentication = true

  admin_ssh_key {
    username   = "azureuser"
    public_key = "PUB_KEY_CONTENT" # Replace with your PUB_KEY
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-focal"
    sku       = "20_04-lts"
    version   = "latest"
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
    name                 = "delo-d-osdisk"
  }

  tags = {
    Environment = "Dev-Sub"
    Product     = "VMCompute"
    Owner       = "infra@delo.com"
    Team        = "InfraTeam"
    Region      = "WestEurope"
    Service     = "VM"
  }
}
