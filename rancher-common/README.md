# Rancher Common Terraform Module

The `rancher-common` module contains all resources that do not depend on a specific cloud provider.  
RKE, Kubernetes, Helm, and Rancher providers are used given the necessary information about the infrastructure created in a cloud provider.

## Variables

###### `node_public_ip`
- Required
Public IP of compute node for Rancher cluster

###### `node_internal_ip`
Internal IP of compute node for Rancher cluster

###### `node_username`
- Required
Username used for SSH access to the Rancher server cluster node

###### `ssh_key_file_name`
File path and name of SSH private key used for infrastructure and RKE.

A private key file name is expected, the public key is assumed to be located at `${ssh_key_file_name}.pub`.

###### `rke_kubernetes_version`
Kubernetes version to use for Rancher server RKE cluster

###### `cert_manager_version`
Version of cert-mananger to install alongside Rancher (format: `0.0.0`)

Used in the case of older Rancher versions.

###### `rancher_version`
Rancher server version (format `v0.0.0`)

###### `rancher_server_dns`
- Required
DNS host name of the Rancher server

A DNS name is required to allow successful SSL cert generation.
SSL certs may only be assigned to DNS names, not IP addresses.
Only an IP address could cause the Custom cluster to fail due to mismatching SSL Subject Names.

###### `admin_password`
- Required
Admin password to use for Rancher server bootstrap

Log in to the Rancher server using username `admin` and this password.

###### `workload_kubernetes_version`
Kubernetes version to use for managed workload cluster

###### `workload_cluster_name`
- Required
Name for created custom workload cluster

