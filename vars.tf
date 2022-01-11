variable resource_prefix {}
variable resource_group_name {}
variable location {
    default = "centralus"
}
variable tags {
    default = null
}
variable hostpool_token {
    sensitive = true
}
variable hostpool_name {}
variable hostpool_resource_group {}
variable dag_id {
    default = null
}
variable "adds_domain_join_upn" {}
variable "adds_domain_join_pass" {}
variable "adds_domain_join_name" {}
variable "adds_ou_path" {
    default = null
}
variable host_computer_name {}
variable host_index {
    default = 1
}
variable host_size {}
variable host_disk_size {
    default = "256"
}
# https://jackstromberg.com/2017/01/list-of-time-zones-consumed-by-azure/
variable host_timezone {
    default = "Central Standard Time"
}
variable host_image_publisher {
    default = "MicrosoftWindowsDesktop"
}
variable host_image_offer {
    default = "Windows-10"
}
variable host_image_sku {
    default = "win10-21h2-ent"
}
variable host_image_version {
    default = "latest"
}
# Encryption at Host - requires provider be registerd on subscription - Register-AzProviderFeature -FeatureName "EncryptionAtHost" -ProviderNamespace "Microsoft.Compute"
variable host_encryption_at_host {
    type    = bool
    default = true
}
variable host_subnet_id {}
variable host_accelerated_networking {
    type    = bool
    default = false
}
variable host_shutdown_time {
    default = null
}
variable host_shutdown_notify_time {
    default = 60
}
variable host_shutdown_notify_webhook {
    default = null
}
variable assigned_user {
    default = null
}