output "rancher_server_url" {
  value = module.rancher_common.rancher_url
}

output "workload_node_ip" {
  value = aws_instance.quickstart_node.public_ip
}
