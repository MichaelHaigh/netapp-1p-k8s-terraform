# Azure NetApp Files and AKS

This Terraform code deploys:

* [anf.tf](./anf.tf): an Azure NetApp Files account and capacity pool (service level and size set via variables)
* [aks.tf](./aks.tf): a basic Managed Kubernetes Cluster, with many options configurable via variables (see [this page](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/kubernetes_cluster) to add any additional arguments).
* [main.tf](./main.tf): required provider versions, including credential file information (see [credentials](#credentials) below for more info)
* [vnet.tf](./vnet.tf): A new virtual network and subnets with necessary network security groups for appropriate inbound access (see [authorized networks](#authorized-networks) below)

Please see the [main readme](../README.md) for information on how to deploy.

## Credentials

The top of the `tfvars` file contains a `sp_creds` variable pointing to the local filepath of a credential file of a [service principal](https://learn.microsoft.com/entra/identity-platform/app-objects-and-service-principals) which as the following format:

```text
{
        "subscriptionId": "acb5685a-dead-4d22-beef-ad9330cd14b4",
        "appId": "c16a3d0b-dead-4a32-beef-576623b3706c",
        "displayName": "azure-sp-terraform",
        "password": "11F8Q~4deadbeefNOBbOtnOfN3~FRhrsD9N0SaCP",
        "tenant": "d26875b4-dead-456e-beef-bafc77f348b5"
}
```

If you need to create a new service principal, please follow [these steps](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/guides/service_principal_client_secret.html#creating-a-service-principal-in-the-azure-portal) (the [contributor role](https://learn.microsoft.com/azure/role-based-access-control/built-in-roles) will have all the necessary privileges). The `subscriptionId` field can be gathered from the [subscription blade](https://portal.azure.com/#view/Microsoft_Azure_Billing/SubscriptionsBladeV1), the `appId` (also known as the client ID), `displayName`, and `tenant` (also known as the directory ID) fields can be gathered from the [app registration blade](https://portal.azure.com/#view/Microsoft_AAD_IAM/ActiveDirectoryMenuBlade/~/RegisteredApps/RegisteredApps/Overview) (step 1 in the above instructions), and the `password` field can be gathered (*only* at time of creation) from the `Certificates & secrets: client secrets` page of your app registration (step 2 in the above instructions).

## Authorized Networks

The bottom of the `tfvars` file contains an `authorized_networks` list which permits access to the deployed resources. You should update the values (and optionally add additional values) to match any IP ranges that you wish to access the environment from (`curl http://checkip.amazonaws.com` is a useful command to figure out your IP address).
