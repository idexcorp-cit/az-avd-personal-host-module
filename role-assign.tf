data "azurerm_client_config" "current" {}

data "azuread_user" "assigned_user" {
    for_each    = var.assigned_user != null ? toset(["assign"]) : []

    user_principal_name = var.assigned_user
}

resource "azurerm_role_assignment" "assign" {
    for_each    = var.assigned_user != null ? toset(["assign"]) : []

    scope                   = var.dag_id
    role_definition_name    = "Desktop Virtualization User"
    principal_id            = data.azuread_user.assigned_user["assign"].object_id

    provisioner "local-exec" {
        command = <<-SCRIPT
                    $secret = ConvertTo-SecureString -String $env:ARM_CLIENT_SECRET -AsPlainText -Force;
                    $credential = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $env:ARM_CLIENT_ID, $secret;
                    if(-not(Get-InstalledModule Az -ErrorAction SilentlyContinue)) {
                        Install-Module Az.Accounts -Confirm:$False -Force;
                        Install-Module Az.DesktopVirtualization -Confirm:$False -Force
                    };
                    Connect-AzAccount -ServicePrincipal -TenantId $env:ARM_TENANT_ID -Credential $credential -SubscriptionId $env:ARM_SUBSCRIPTION_ID;
                    Update-AzWvdSessionHost -ResourceGroupName ${var.hostpool_resource_group} -HostPoolName ${var.hostpool_name} -SessionHostName ${azurerm_windows_virtual_machine.host.computer_name}.${var.adds_domain_join_name} -SubscriptionId ${data.azurerm_client_config.current.subscription_id} -AssignedUser ${var.assigned_user}
                    SCRIPT
        interpreter = [
            "pwsh", 
            "-command"
        ]
    }

    depends_on = [
        azurerm_virtual_machine_extension.vmext_dsc
    ]
}