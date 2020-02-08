# Outputs

output "rancher_url" {
  value = "https://${var.rancher_server_dns}"
}

output "custom_cluster_command" {
  value       = rancher2_cluster.quickstart.cluster_registration_token.0.node_command
  description = "Docker command used to add a node to the quickstart cluster"
}
