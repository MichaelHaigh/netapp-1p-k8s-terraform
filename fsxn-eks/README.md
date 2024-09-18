# FSx for NetApp ONTAP and EKS

This Terraform code deploys:

* [fsxn.tf](./fsxn.tf): an FSx for NetApp ONTAP filesystem, SVM, and necessary security groups (filesystem size and throughput can be set via variables)
* [eks.tf](./eks.tf): an Elastic Kubernetes Service Cluster, with many options configurable via variables (see [eks\_cluster](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/eks_cluster) and [eks\_node\_group](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/eks_node_group) pages to add any additional arguments), necessary security group rules, and [add-on](https://docs.aws.amazon.com/eks/latest/userguide/eks-add-ons.html) installation.
* [iam.tf](./iam.tf): necessary IAM roles, policies, and attachments for the various resources
* [main.tf](./main.tf): required provider versions, including credential file information (see [credentials](#credentials) below for more info)
* [vpc.tf](./vpc.tf): A new virtual private cloud and subnets with necessary route tables, nat gateways, and security groups for appropriate inbound (see [authorized networks](#authorized-networks) below) and outbound access

Please see the [main readme](../README.md) for information on how to deploy.

## Credentials

The top of the `tfvars` file contains a `aws_cred_file` variable pointing to the local filepath of an [access key file](https://docs.aws.amazon.com/IAM/latest/UserGuide/id_credentials_access-keys.html) which as the following format:

```text
{
        "aws_access_key_id": "AKIAIOSFODNN7EXAMPLE",
        "aws_secret_access_key": "wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY"
}
```

## Authorized Networks

The bottom of the `tfvars` file contains an `authorized_networks` list which permits access to the deployed resources. You should update the values (and optionally add additional values) to match any IP ranges that you wish to access the environment from (`curl http://checkip.amazonaws.com` is a useful command to figure out your IP address).
