# Local resources

# Save kubeconfig file for interacting with the RKE cluster on your local machine
resource "local_file" "kube_config_yaml" {
  filename = format("%s/%s", path.root, "kube_config.yaml")
  content  = rke_cluster.rancher_cluster.kube_config_yaml
}
