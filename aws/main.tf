variable "aws_access_key" {
  default     = "xxx"
  description = "Amazon AWS Access Key"
}

variable "aws_secret_key" {
  default     = "xxx"
  description = "Amazon AWS Secret Key"
}

variable "prefix" {
  default     = "yourname"
  description = "Cluster Prefix - All resources created by Terraform have this prefix prepended to them"
}

variable "rancher_version" {
  default     = "latest"
  description = "Rancher Server Version"
}

variable "count_agent_all_nodes" {
  default     = "1"
  description = "Number of Agent All Designation Nodes"
}

variable "count_agent_etcd_nodes" {
  default     = "0"
  description = "Number of ETCD Nodes"
}

variable "count_agent_controlplane_nodes" {
  default     = "0"
  description = "Number of K8s Control Plane Nodes"
}

variable "count_agent_worker_nodes" {
  default     = "0"
  description = "Number of Worker Nodes"
}

variable "admin_password" {
  default     = "admin"
  description = "Password to set for the admin account in Rancher"
}

variable "cluster_name" {
  default     = "quickstart"
  description = "Kubernetes Cluster Name"
}

variable "region" {
  default     = "us-west-2"
  description = "Amazon AWS Region for deployment"
}

variable "type" {
  default     = "t3.medium"
  description = "Amazon AWS Instance Type"
}

variable "docker_version_server" {
  default     = "19.03"
  description = "Docker Version to run on Rancher Server"
}

variable "docker_version_agent" {
  default     = "19.03"
  description = "Docker Version to run on Kubernetes Nodes"
}

variable "ssh_key_file_name" {
  default     = "~/.ssh/id_rsa"
  description = "Full file path and name of key used for SSH access"
}


provider "local" {
  version = "~> 1.4"
}

provider "template" {
  version = "~> 2.1"
}

provider "aws" {
  version = "~> 2.41"

  access_key = var.aws_access_key
  secret_key = var.aws_secret_key
  region     = var.region
}

provider "rke" {
  version = "~> 0.14"
}

provider "kubernetes" {
  version = "~> 1.10"

  host = rke_cluster.rancher_cluster.api_server_url

  client_certificate     = rke_cluster.rancher_cluster.client_cert
  client_key             = rke_cluster.rancher_cluster.client_key
  cluster_ca_certificate = rke_cluster.rancher_cluster.ca_crt

  load_config_file = false
}

provider "helm" {
  version = "~> 0.10"

  tiller_image    = "gcr.io/kubernetes-helm/tiller:v2.16.1"
  service_account = "tiller"

  kubernetes {
    host = rke_cluster.rancher_cluster.api_server_url

    client_certificate     = rke_cluster.rancher_cluster.client_cert
    client_key             = rke_cluster.rancher_cluster.client_key
    cluster_ca_certificate = rke_cluster.rancher_cluster.ca_crt

    load_config_file = false
  }
}

# Rancher2 bootstrapping provider
provider "rancher2" {
  version = "~> 1.7"

  alias = "bootstrap"

  api_url  = "https://${aws_instance.rancher_server.public_dns}"
  insecure = true
  # ca_certs  = data.kubernetes_secret.rancher_cert.data["ca.crt"]
  bootstrap = true
}

# Rancher2 administration provider
provider "rancher2" {
  version = "~> 1.7"

  alias = "admin"

  api_url  = "https://${aws_instance.rancher_server.public_dns}"
  insecure = true
  # ca_certs  = data.kubernetes_secret.rancher_cert.data["ca.crt"]
  token_key = rancher2_bootstrap.admin.token
}


# Use latest Ubuntu 18.04 AMI
data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"] # Canonical

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-bionic-18.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# Rancher Helm repository
data "helm_repository" "rancher_stable" {
  name = "rancher-stable"
  url  = "https://releases.rancher.com/server-charts/stable"
}

# Jetstack Helm repository
data "helm_repository" "jetstack" {
  name = "jetstack"
  url  = "https://charts.jetstack.io"
}

# Security group to allow all traffic
resource "aws_security_group" "rancher_sg_allowall" {
  name        = "${var.prefix}-rancher-allowall"
  description = "Rancher quickstart - allow all traffic"

  ingress {
    from_port   = "0"
    to_port     = "0"
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = "0"
    to_port     = "0"
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Creator = "rancher-quickstart"
  }
}

# Temporary key pair used for SSH accesss
resource "aws_key_pair" "quickstart_key_pair" {
  key_name_prefix = "${var.prefix}-rancher-"
  public_key      = file("${var.ssh_key_file_name}.pub")
}

# Templated shell script for cloud-init user data in Rancher server
data "template_file" "userdata_server" {
  template = file("../cloud-common/files/userdata")

  vars = {
    docker_version_server = var.docker_version_server
  }
}

# Full cloud-init user data for Rancher Server
data "template_cloudinit_config" "rancher_server_cloudinit" {
  part {
    content_type = "text/cloud-config"
    content      = "hostname: ${var.prefix}-rancher-server\nmanage_etc_hosts: true"
  }

  part {
    content_type = "text/x-shellscript"
    content      = data.template_file.userdata_server.rendered
  }
}

# AWS EC2 for creating a single node RKE cluster and installing the Rancher server
resource "aws_instance" "rancher_server" {
  ami             = data.aws_ami.ubuntu.id
  instance_type   = var.type
  key_name        = aws_key_pair.quickstart_key_pair.key_name
  security_groups = [aws_security_group.rancher_sg_allowall.name]
  user_data       = data.template_cloudinit_config.rancher_server_cloudinit.rendered

  provisioner "remote-exec" {
    inline = [
      "cloud-init status --wait",
      "sudo usermod -a -G docker ubuntu"
    ]

    connection {
      type        = "ssh"
      host        = self.public_ip
      user        = "ubuntu"
      private_key = file(var.ssh_key_file_name)
    }
  }

  tags = {
    Name    = "${var.prefix}-rancher-server"
    Creator = "rancher-quickstart"
  }
}

# RKE cluster installed on the stood up EC2 node
resource "rke_cluster" "rancher_cluster" {
  cluster_name = var.cluster_name

  nodes {
    address          = aws_instance.rancher_server.public_ip
    user             = "ubuntu"
    role             = ["controlplane", "etcd", "worker"]
    internal_address = aws_instance.rancher_server.private_ip
    ssh_key          = file(var.ssh_key_file_name)
  }
}

# Save kubeconfig file for interacting with the RKE cluster on your local machine
resource "local_file" "kube_config_yaml" {
  filename = format("%s/%s", path.root, "kube_config.yaml")
  content  = rke_cluster.rancher_cluster.kube_config_yaml
}

# Create tiller service account
resource "kubernetes_service_account" "tiller" {
  depends_on = [rke_cluster.rancher_cluster]

  metadata {
    name      = "tiller"
    namespace = "kube-system"
  }

  automount_service_account_token = true
}

# Bind tiller service account to cluster-admin
resource "kubernetes_cluster_role_binding" "tiller_admin" {
  depends_on = [rke_cluster.rancher_cluster]

  metadata {
    name = "tiller-admin"
  }
  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = "cluster-admin"
  }
  subject {
    kind      = "ServiceAccount"
    name      = kubernetes_service_account.tiller.metadata[0].name
    namespace = "kube-system"
  }
}

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
          image   = "gcr.io/google-containers/kubectl:v1.16.3"
          command = ["kubectl", "apply", "-f", "https://raw.githubusercontent.com/jetstack/cert-manager/release-0.12/deploy/manifests/00-crds.yaml", "--validate=false"]
          # command = ["kubectl", "apply", "-f", "https://raw.githubusercontent.com/jetstack/cert-manager/release-0.9/deploy/manifests/00-crds.yaml"]
          # kubectl apply -f https://raw.githubusercontent.com/jetstack/cert-manager/release-0.9/deploy/manifests/00-crds.yaml
        }
        automount_service_account_token = true
        restart_policy                  = "Never"
        service_account_name            = kubernetes_service_account.cert_manager_crd.metadata[0].name
        host_network                    = true
      }
    }
  }
}

# Install cert-manager helm chart
resource "helm_release" "cert_manager" {
  depends_on = [kubernetes_service_account.tiller, kubernetes_cluster_role_binding.tiller_admin, kubernetes_job.install_certmanager_crds, kubernetes_service_account.cert_manager_crd, kubernetes_cluster_role_binding.cert_manager_crd_admin]

  name       = "cert-manager"
  namespace  = "cert-manager"
  version    = "v0.12.0"
  repository = data.helm_repository.jetstack.metadata[0].name
  chart      = "cert-manager"
}

# Install Rancher helm chart
resource "helm_release" "rancher_server" {
  depends_on = [kubernetes_service_account.tiller, kubernetes_cluster_role_binding.tiller_admin, kubernetes_service_account.tiller, kubernetes_cluster_role_binding.tiller_admin, helm_release.cert_manager]

  name       = "rancher"
  namespace  = "cattle-system"
  version    = "v2.3.5"
  repository = data.helm_repository.rancher_stable.metadata[0].name
  chart      = "rancher"

  set {
    name  = "hostname"
    value = aws_instance.rancher_server.public_dns
  }
}

# data "kubernetes_secret" "rancher_cert" {
#   depends_on = [helm_release.rancher_server]

#   metadata {
#     name      = "tls-rancher-ingress"
#     namespace = "cattle-system"
#   }
# }

# Initialize Rancher server
resource "rancher2_bootstrap" "admin" {
  depends_on = [helm_release.rancher_server]

  provider = rancher2.bootstrap

  password  = var.admin_password
  telemetry = true
}

# Create cloud credentials for AWS
resource "rancher2_cloud_credential" "aws_quickstart" {
  depends_on = [rancher2_bootstrap.admin]

  provider = rancher2.admin

  name        = "aws-quickstart"
  description = "AWS Cloud Credentials used to create AWS quickstart infrastructure"

  amazonec2_credential_config {
    access_key = var.aws_access_key
    secret_key = var.aws_secret_key
  }
}

output "rancher-url" {
  value = ["https://${aws_instance.rancher_server.public_dns}"]
}

