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
resource "rancher2_cluster" "quickstart" {
  provider = rancher2.admin

  name        = "quickstart"
  description = "Custom cluster created for quickstart"

  rke_config {
    kubernetes_version = var.rke_kubernetes_version
  }
}
