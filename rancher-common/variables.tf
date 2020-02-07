# Variables for rancher common module

variable "ssh_key_file_name" {
  type        = string
  description = "File path and name of SSH private key used for infrastructure and RKE"
  default     = "~/.ssh/id_rsa"
}

# Required
variable "node_public_ip" {
  type        = string
  description = "Public IP of compute node for Rancher cluster"
}

variable "node_internal_ip" {
  type        = string
  description = "IP of compute node for Rancher cluster used for internal cluster communication"
  default     = ""
}

variable "rke_kubernetes_version" {
  type        = string
  description = "RKE version to use for Rancher server cluster"
  default     = "v1.15.3-rancher1-1"
}

variable "cert_manager_version" {
  type        = string
  description = "Version of cert-mananger to install alongside Rancher (format: 0.0.0)"
  default     = "0.12.0"
}

variable "rancher_version" {
  type        = string
  description = "Rancher server version (format v0.0.0)"
  default     = "v2.3.5"
}

# Required
variable "rancher_server_dns" {
  type        = string
  description = "DNS host name of the Rancher server"
}

variable "admin_password" {
  type        = string
  description = "Admin password to use for Rancher server bootstrap"
}
