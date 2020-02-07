# Quickstart examples for Rancher

Quikly stand up an HA-style Rancher management cluster in your infrastructure provider of choice.

Intended for experimentation/evaluation ONLY.

**You will be responsible for any and all infrastructure costs incurred by these resources.**
As a result, this repository minimizes costs by standing up the minimum required resources for a given provider.
Use Vagrant to run Rancher locally and avoid cloud costs.

## Local quickstart

A local quickstart is provided in the form of Vagrant configuration.
See [/vagrant](./vagrant) for usage details.

### Requirements - Vagrant (local)

- [Vagrant](https://www.vagrantup.com)
- [VirtualBox](https://www.virtualbox.org)
- 6GB unused RAM

## Cloud quickstart

Quickstarts are provided for AWS, Azure, DigitalOcean, and Google Cloud Platform.

**You will be responsible for any and all infrastructure costs incurred by these resources.**

By default, each quickstart will install Rancher on a single-node RKE cluster, then will provision another single-node cluster using a Custom cluster in Rancher.
This option provides easy access to the core Rancher functionality while establishing a foundation that can be easily expanded to a full HA Rancher server.

The `rancher_server_node_count` variable is provided to configure the size of the cluster used to host Rancher.

Variables of the form `upstream_*` are used to configure the numbers of each kind of node in the provisioned cluster that will be managed by Rancher.

### Requirements - Cloud

- Terraform >=0.12.0
- RKE terraform provider installed locally

## DO quick start

**NOTE:** Terraform 0.12.0 or higher is required.

The DO folder contains terraform code to stand up a single Rancher server instance with a 3 node cluster attached to it.

This terraform setup will:

- Start a droplet running `rancher/rancher` version specified in `rancher_version`
- Create a custom cluster called `cluster_name`
- Start `count_agent_all_nodes` amount of droplets and add them to the custom cluster with all roles

### How to use

- Clone this repository and go into the DO subfolder
- Move the file `terraform.tfvars.example` to `terraform.tfvars` and edit (see inline explanation)
- Run `terraform init`
- Run `terraform apply`

When provisioning has finished you will be given the url to connect to the Rancher Server

### How to Remove

To remove the VM's that have been deployed run `terraform destroy --force`

### Optional adding nodes per role
- Start `count_agent_etcd_nodes` amount of droplets and add them to the custom cluster with etcd role
- Start `count_agent_controlplane_nodes` amount of droplets and add them to the custom cluster with controlplane role
- Start `count_agent_worker_nodes` amount of droplets and add them to the custom cluster with worker role

**Please be aware that you will be responsible for the usage charges with Digital Ocean**

## Amazon AWS Quick Start

**NOTE:** Terraform 0.12.0 or higher is required.

The aws folder contains terraform code to stand up a single Rancher server instance with a 1 node cluster attached to it.

You will need the following:

- An AWS Account with an access key and secret key
- The name of a pre-created AWS Key Pair
- Your desired AWS Deployment Region

This terraform setup will:

- Start an Amazon AWS EC2 instance running `rancher/rancher` version specified in `rancher_version`
- Create a custom cluster called `cluster_name`
- Start `count_agent_all_nodes` amount of AWS EC2 instances and add them to the custom cluster with all roles

### How to use

- Clone this repository and go into the aws subfolder
- Move the file `terraform.tfvars.example` to `terraform.tfvars` and edit (see inline explanation)
- Run `terraform init`
- Run `terraform apply`

When provisioning has finished you will be given the url to connect to the Rancher Server

### How to Remove

To remove the VM's that have been deployed run `terraform destroy --force`

### Optional adding nodes per role
- Start `count_agent_all_nodes` amount of AWS EC2 Instances and add them to the custom cluster with all role
- Start `count_agent_etcd_nodes` amount of AWS EC2 Instances and add them to the custom cluster with etcd role
- Start `count_agent_controlplane_nodes` amount of AWS EC2 Instances and add them to the custom cluster with controlplane role
- Start `count_agent_worker_nodes` amount of AWS EC2 Instances and add them to the custom cluster with worker role

**Please be aware that you will be responsible for the usage charges with Amazon AWS**
