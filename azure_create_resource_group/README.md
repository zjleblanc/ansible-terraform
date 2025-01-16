# Create Resource Group

Example Terraform project used to learn workflow and authentication using the AzureRM Provider.

## Environment Variables for Azure CLI

When these environment variables are defined, you do not need to explicitly pass values to the azurerm provider for authentication. This is the method I use in my demo.

```bash
export ARM_CLIENT_ID=<guid>
export ARM_CLIENT_SECRET=<secret>
export ARM_TENANT_ID=contoso.onmicrosoft.com
export ARM_SUBSCRIPTION_ID=<guid>
```

## Environment Variables for AzureRM Provider

These enviroments would be supplied to satisfy the associated entries in [variables.tf](variables.tf). The prefix **TF_VAR_** is important, but the full name just needs to match your usage in the Terraform files.

```bash
export TF_VAR_az_client_id=<guid>
export TF_VAR_az_client_secret=<secret>
export TF_VAR_az_tenant=contoso.onmicrosoft.com
export TF_VAR_az_subscription=<guid>
```

Ultimately, the values end up being passed to the provider configuration in [providers.tf](providers.tf) (commented):

```
...
provider "azurerm" {
  features {}

  # client_id       = var.az_client_id
  # client_secret   = var.az_client_secret
  # tenant_id       = var.az_tenant
  # subscription_id = var.az_subscription
}
```