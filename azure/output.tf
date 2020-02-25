output "rancher_server_url" {
  value = module.rancher_common.rancher_url
}

output "workload_node_ip" {
  value = azurerm_linux_virtual_machine.quickstart-node.public_ip_address
}
