resource "random_string" "password" {
    length  = 24
    upper   = true
    lower   = true
    number  = true
    special = false
}

resource "azurerm_network_interface" "host" {
    name                = "${var.resource_prefix}-vm-nic"
    resource_group_name = var.resource_group_name
    location            = var.location

    enable_accelerated_networking = var.host_accelerated_networking

    ip_configuration {
        name       = "${var.resource_prefix}-vm-nic"
        subnet_id  = var.host_subnet_id

        private_ip_address_allocation = "Dynamic"
    }

    tags = var.tags
}

resource "azurerm_windows_virtual_machine" "host" {
    name                = "${var.resource_prefix}-vm-${var.host_index}"
    computer_name       = "${var.host_computer_name}-${var.host_index}"
    resource_group_name = var.resource_group_name
    location            = var.location

    size                = var.host_size

    admin_username      = "azureuser"
    admin_password      = random_string.password.result
    timezone            = var.host_timezone

    encryption_at_host_enabled = var.host_encryption_at_host

    network_interface_ids = [ azurerm_network_interface.host.id ]
    
    boot_diagnostics {}

    os_disk {
        caching                 = "ReadWrite"
        storage_account_type    = "Premium_LRS"
        disk_size_gb            = var.host_disk_size
    }

    source_image_reference {
        publisher   = var.host_image_publisher
        offer       = var.host_image_offer
        sku         = var.host_image_sku
        version     = var.host_image_version
    }

    tags = var.tags

    lifecycle {
        ignore_changes = [tags]
    }
}

output "host_vm_id" {
    value = azurerm_windows_virtual_machine.host.id
}

output "host_vm_resource_name" {
    value = azurerm_windows_virtual_machine.host.name
}

output "host_vm_computer_name" {
    value = azurerm_windows_virtual_machine.host.computer_name
}