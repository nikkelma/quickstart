
output "rancher_server_url" {
  value = module.rancher_common.rancher_url
}

output "workload_node_ip" {
  value = digitalocean_droplet.quickstart_node.ipv4_address
}
