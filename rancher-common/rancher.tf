# Rancher resources

# Initialize Rancher server
resource "rancher2_bootstrap" "admin" {
  depends_on = [
    helm_release.rancher_server
  ]

  provider = rancher2.bootstrap

  password  = var.admin_password
  telemetry = true
}

# Create custom managed cluster for quickstart
resource "rancher2_cluster" "quickstart_workload" {
  provider = rancher2.admin

  name        = "quickstart-workload"
  description = "Custom workload cluster created for quickstart"

  rke_config {
    kubernetes_version = var.workload_kubernetes_version
  }
}
