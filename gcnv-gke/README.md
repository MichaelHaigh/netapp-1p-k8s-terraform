# Google Cloud NetApp Volumes and GKE

This Terraform code deploys:

* [gcnv.tf](./gcnv.tf): a Google Cloud NetApp Volumes storage pool (service level and size set via variables)
* [gke.tf](./gke.tf): a **zonal** GKE cluster, with most other options configurable via variables.
* [main.tf](./main.tf): required provider versions, including credential file information
* [vpc.tf](./vpc.tf): A new VPC, subnetwork with necessary secondary networks, firewall, router and NAT gateway for egress internet access, and GCNV network peering.

Please see the [main readme](../README.md) for information on how to deploy.

## Credentials

The top of the `tfvars` file contains several variables that must be updated for your environment:

```text
sa_creds           = "~/.gcp/astracontroltoolkitdev-terraform-sa-f8e9.json"
gcp_sa             = "terraform-sa@astracontroltoolkitdev.iam.gserviceaccount.com"
gcp_project        = "astracontroltoolkitdev"
gcp_project_number = "239048101169"
```

* `sa_creds`: the local filepath to the [service account credential](https://cloud.google.com/iam/docs/service-account-creds#key-types)
* `gcp_sa`: the service account principal
* `gcp_project`: the name of your GCP project
* `gcp_project_number`: the number of your GCP project (can be found by running `gcloud projects describe $(gcloud config get-value project)`)

## Authorized Networks

The bottom of the `tfvars` file contains an `authorized_networks` list which permits access to the deployed resources. You should update the values (and optionally add additional values) to match any IP ranges that you wish to access the environment from (`curl http://checkip.amazonaws.com` is a useful command to figure out your IP address).
