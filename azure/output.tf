output "rancher_server_url" {
  value = module.rancher_common.rancher_url
}

output "workload_node_ip" {
  value = azurerm_public_ip.quickstart-node-pip.ip_address
}
