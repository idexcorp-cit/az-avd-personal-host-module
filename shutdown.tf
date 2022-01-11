resource "azurerm_dev_test_global_vm_shutdown_schedule" "host" {
    for_each            = var.host_shutdown_time != null ? toset(["shutdown"]) : []

    virtual_machine_id  = azurerm_windows_virtual_machine.host.id
    location            = var.location
    enabled             = true

    daily_recurrence_time   = var.host_shutdown_time
    timezone                = var.host_timezone

    notification_settings {
        enabled         = true
        time_in_minutes = var.host_shutdown_notify_time
        email           = var.host_shutdown_notify_webhook != null ? null : var.assigned_user
        webhook_url     = var.host_shutdown_notify_webhook
    }

    tags = var.tags
}