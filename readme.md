# Azure Virtual Desktop Personal Hostpool Module
![GitHub commits since latest release (by date)](https://img.shields.io/github/commits-since/idexcorp-cit/az-avd-personal-host-module/latest/main)

This Terraform module is designed to deploy an Azure Virtual Desktop Host as a Personal Desktop. This can be used in conjunction with the [az-avd-personal-hostpool-module](https://github.com/idexcorp-cit/az-avd-personal-hostpool-module) and [az-avd-hostpool-token-module](https://github.com/idexcorp-cit/az-avd-hostpool-token-module) modules.

This module assumes that the following items:
- Environment variables are set
    - `ARM_SUBSCRIPTION_ID`
    - `ARM_TENANT_ID`
    - `ARM_CLIENT_ID`
    - `ARM_CLIENT_SECRET`
- Powershell 6+ is installed and can install Az.Accounts and Az.DesktopVirtualization modules.

This module has the following parameters that can be set:
- `resource_prefix` - **Required** - Prefix for resources created in this module.
- `resource_group_name` - **Required** - Resource group resources in this module should be added to.
- `location` - **Required** - Location resources in this module will be located in.
- `hostpool_token` - **Required** - Registration Info Token used to add the VM to the Hostpool.
- `hostpool_name` - **Required** - Name of the Hostpool to add the VM to.
- `hostpool_resource_group` - **Required** - Resource group name where the Hostpool resides.
- `dag_id` - **Required** - Desktop application group ID/
- `adds_domain_join_upn` - **Required** - User principal name used to join the VM to AD.
- `adds_domain_join_pass` - **Required** - Password for the above user.
- `adds_domain_join_name` - **Required** - Name of the AD Domain.
- `host_computer_name` - **Required** - Hostname of the VM, what is used to join to AD.
- `host_index`- **Required** - Number associated with the host, increment by 1. Is appeneded to VM resource name and the VM computer name.
- `assigned_user`- **Required** - User that will be assigned to this Host.
- `host_subnet_id`- **Required** - Subnet to attach the VM to (will require connectivity to ADDS).
- `host_size` - **Required** - VM SKU.
- `tags` - **Not Required** - Azure resource tags.
- `adds_ou_path` - **Not Required** - ADDS OU Path.
- `host_disk_size` - **Not Required** - Size of disk to provision (defaults to 256GB)
- `host_timezone` - **Not Required** - Timezone to set the VM to (defaults to CST)
- `host_image_publisher` - **Not Required** - VM Image Publisher (defaults to MicrosoftWindowsDesktop).
- `host_image_offer` - **Not Required** - VM Image Offer (defaults to Windows-10).
- `host_image_sku` - **Not Required** - VM Image SKU (defaults to win10-21h2-ent).
- `host_image_version` - **Not Required** - VM Image Version (defaults to latest).
- `host_encryption_at_host` - **Not Required** - Enable Encryption at Host - requires feature to be enabled on subscription (defaults to true).
- `host_accelerated_networking` - **Not Required** - Enable accelerated networking - requires compatible VM SKU (defaults to false).
- `host_shutdown_time` - **Not Required** - 24Hr Format as 1700 for 5:00PM.
- `host_shutdown_notify_time` - **Not Required** - Send notification x minutes prior to shutdown (defaults to 60).
- `host_shutdown_notify_webhook` - **Not Required** - Webhook URL for shutdown notifications.


This module will have the following attributes output:
- `host_vm_id` - ID of the Virtual Machine Resource
- `host_vm_resource_name` - Name of the Virtual Machine Resource
- `host_vm_computer_name` - Computer Name of the Virtual Machine (name that you see in the VM/Active Directory)

Here is an example:
```terraform
module "hostpool" {
    source              = "git::https://github.com/idexcorp-cit/az-avd-personal-hostpool-module.git?ref=v0.1.0"

    resource_prefix = "eus-avd"
    location        = "eastus"
    friendly_name   = "East US AVD"
    
    tags = var.common_tags
}

module "hostpool_token" {
    source                  = "git::https://github.com/idexcorp-cit/az-avd-hostpool-token-module.git?ref=v0.1.0"

    hostpool_resource_group = module.hostpool.resource_group_name
    hostpool_name           = module.hostpool.hostpool_name
    token_valid_hours       = 3
}

resource "azurerm_resource_group" "avd_host" {
    for_each    = var.avd_users

    name        = "eus-avd-${each.key}-rg"
    location    = module.hostpool.resource_group_location

    tags = merge(
        tomap({"avd_user" = lookup(each.value, "user")}),
        var.common_tags
    )
}

module "host" {
    source                  = "git::https://github.com/idexcorp-cit/az-avd-personal-host-module.git?ref=v0.1.0"

    for_each                = var.avd_users

    resource_prefix         = "eus-avd-${each.key}"
    resource_group_name     = azurerm_resource_group.avd_host[each.key].name
    location                = azurerm_resource_group.avd_host[each.key].location
    hostpool_name           = module.hostpool.hostpool_name
    hostpool_token          = module.hostpool_token.token
    hostpool_resource_group = module.hostpool.resource_group_name
    dag_id                  = module.hostpool.dag_id
    host_subnet_id          = var.subnet_id
    host_encryption_at_host = true
    
    adds_domain_join_upn    = var.adds_domain_join_upn
    adds_domain_join_pass   = var.adds_domain_join_pass
    adds_domain_join_name   = var.adds_domain_join_name
    adds_ou_path            = var.adds_ou_path

    assigned_user       = lookup(each.value, "user")
    host_computer_name  = lookup(each.value, "computer_name_override", "avd${substr(var.department_shortname, 0, 3)}${substr(each.key, 0, 7)}")
    host_index          = lookup(each.value, "index")
    host_size           = lookup(each.value, "size", "Standard_D2s_v4")
    host_disk_size      = lookup(each.value, "disk_size", "256")
    host_timezone       = lookup(each.value, "timezone", "Eastern Standard Time")
    host_image_offer    = lookup(each.value, "image_offer", "Windows-10")
    host_image_sku      = lookup(each.value, "image_sku", "win10-21h2-ent")
    host_shutdown_time  = lookup(each.value, "shutdown_time", null)
}
```