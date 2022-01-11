resource "azurerm_virtual_machine_extension" "domain_join" {
    name                       = "${azurerm_windows_virtual_machine.host.computer_name}-domainJoin"
    virtual_machine_id         = azurerm_windows_virtual_machine.host.id
    publisher                  = "Microsoft.Compute"
    type                       = "JsonADDomainExtension"
    type_handler_version       = "1.3"
    auto_upgrade_minor_version = true

    settings = <<SETTINGS
        {
            "Name": "${var.adds_domain_join_name}",
            "OUPath": "${var.adds_ou_path}",
            "User": "${var.adds_domain_join_upn}",
            "Restart": "true",
            "Options": "3"
        }
    SETTINGS

    protected_settings = <<PROTECTED_SETTINGS
        {
            "Password": "${var.adds_domain_join_pass}"
        }
    PROTECTED_SETTINGS

    lifecycle {
        ignore_changes = [settings, protected_settings]
    }

}

resource "azurerm_virtual_machine_extension" "vmext_dsc" {
    name                       = "${azurerm_windows_virtual_machine.host.computer_name}-avd_dsc"
    virtual_machine_id         = azurerm_windows_virtual_machine.host.id
    publisher                  = "Microsoft.Powershell"
    type                       = "DSC"
    type_handler_version       = "2.73"
    auto_upgrade_minor_version = true

    settings = <<-SETTINGS
        {
            "modulesUrl": "https://raw.githubusercontent.com/Azure/RDS-Templates/master/ARM-wvd-templates/DSC/Configuration.zip",
            "configurationFunction": "Configuration.ps1\\AddSessionHost",
            "properties": {
                "HostPoolName":"${var.hostpool_name}"
            }
        }
    SETTINGS

    protected_settings = <<PROTECTED_SETTINGS
    {
        "properties": {
            "registrationInfoToken": "${var.hostpool_token}"
        }
    }
    PROTECTED_SETTINGS

    depends_on = [
        azurerm_virtual_machine_extension.domain_join
    ]

    lifecycle {
        ignore_changes = [protected_settings]
    }
}