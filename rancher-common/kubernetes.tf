# Kubernetes resources

# # Create tiller service account
# resource "kubernetes_service_account" "tiller" {
#   depends_on = [rke_cluster.rancher_cluster]

#   metadata {
#     name      = "tiller"
#     namespace = "kube-system"
#   }

#   automount_service_account_token = true
# }

# # Bind tiller service account to cluster-admin
# resource "kubernetes_cluster_role_binding" "tiller_admin" {
#   depends_on = [rke_cluster.rancher_cluster]

#   metadata {
#     name = "tiller-admin"
#   }
#   role_ref {
#     api_group = "rbac.authorization.k8s.io"
#     kind      = "ClusterRole"
#     name      = "cluster-admin"
#   }
#   subject {
#     kind      = "ServiceAccount"
#     name      = kubernetes_service_account.tiller.metadata[0].name
#     namespace = "kube-system"
#   }
# }

# Create cert-manager-crd service account
resource "kubernetes_service_account" "cert_manager_crd" {
  depends_on = [rke_cluster.rancher_cluster]

  metadata {
    name      = "cert-manager-crd"
    namespace = "kube-system"
  }

  automount_service_account_token = true
}

# Bind cert-manager-crd service account to cluster-admin
resource "kubernetes_cluster_role_binding" "cert_manager_crd_admin" {
  depends_on = [rke_cluster.rancher_cluster]

  metadata {
    name = "${kubernetes_service_account.cert_manager_crd.metadata[0].name}-admin"
  }
  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = "cluster-admin"
  }
  subject {
    kind      = "ServiceAccount"
    name      = kubernetes_service_account.cert_manager_crd.metadata[0].name
    namespace = "kube-system"
  }
}

# Create and run job to install cert-manager CRDs
resource "kubernetes_job" "install_certmanager_crds" {
  metadata {
    name      = "install-certmanager-crds"
    namespace = "kube-system"
  }
  spec {
    template {
      metadata {}
      spec {
        container {
          name    = "hyperkube"
          image   = "rancher/hyperkube:${var.rke_kubernetes_version}"
          command = ["kubectl", "apply", "-f", "https://raw.githubusercontent.com/jetstack/cert-manager/release-0.12/deploy/manifests/00-crds.yaml", "--validate=false"]
        }
        host_network                    = true
        automount_service_account_token = true
        service_account_name            = kubernetes_service_account.cert_manager_crd.metadata[0].name
        restart_policy                  = "Never"
      }
    }
  }
}
