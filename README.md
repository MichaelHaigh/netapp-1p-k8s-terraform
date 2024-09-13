# NetAppp 1st Party Cloud Storage and Kubernetes Terraform IaC

This repository contains Terraform code which creates NetAppp 1st-Party Cloud Storage with the corresponding hyperscaler Kubernetes-as-a-Service offering:

* Amazon [Elastic Kubernetes Service (EKS)](https://aws.amazon.com/eks/) with [FSx for NetApp ONTAP](https://aws.amazon.com/fsx/netapp-ontap/)
* [Azure Kubernetes Service](https://azure.microsoft.com/products/kubernetes-service) with [Azure NetApp Files](https://azure.microsoft.com/products/netapp)
* [Google Kubernetes Engine (GKE)](https://cloud.google.com/kubernetes-engine) with [Google Cloud NetApp Volumes](https://cloud.google.com/netapp-volumes)

The finer details will vary between hyperscaler, however overall each implementation will deploy the following resources:

* Isolated networking (VPC)
* Necessary Identity and Access Management (IAM) policies/roles
* 1st-Party NetApp Storage
* A Kubernetes cluster with:
  * [Trident CSI](https://docs.netapp.com/us-en/netapp-solutions/containers/rh-os-n_overview_trident.html) installed
  * [Trident backends](https://docs.netapp.com/us-en/trident/trident-use/backends.html) configured
  * [Storage class(es)](https://kubernetes.io/docs/concepts/storage/storage-classes/) created and set as default

## Getting Started

Simply change into the hyperscaler directory of your choice, and initialize terraform:

```text
terraform init
```

The provider version in each `main.tf` file is constrained by the `~>` operator to ensure code compatibility, however feel free to change to a different operator if required.

Next, update the `default.tfvars` file to have the deployment parameters of choosing. Additional information on their meanings can be found in the `variables.tf` file.

Plan your deployment with the following command (more information on [workspaces](#workspaces-support) in the section below):

```text
terraform plan -var-file="$(terraform workspace show).tfvars"
```

Create your deployment:

```text
terraform apply -var-file="$(terraform workspace show).tfvars"
```

When your deployment is no longer needed, run the following command to clean up all resources:

```text
terraform destroy -var-file="$(terraform workspace show).tfvars"
```

## Workspaces Support

All code in this respository has been designed to support [Terraform Workspaces](https://developer.hashicorp.com/terraform/cli/workspaces). This enables multiple deployments (for example: `prod` and `dr`, and/or `useast1` and `useast2`) of the same type of environments. To create new workspaces (beyond the `default` workspace), run the following command:

```text
terraform workspace new <workspace-name>
```

Next, copy the `default.tfvars` file (be sure to match your workspace name):

```text
cp default.tfvars <workspace-name>.tfvars
```

Optionally edit the `<workspace-name>.tfvars` file, and then deploy the new environment with the same command:

```text
terraform apply -var-file="$(terraform workspace show).tfvars"
```

To switch to a different workspace, run:

```text
terraform workspace select <workspace-name>
```

To view all available workspaces, run:

```text
terraform workspace list
```
