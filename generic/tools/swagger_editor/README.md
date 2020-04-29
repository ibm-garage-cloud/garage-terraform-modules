# Swagger Editor Module

Installs the Swagger Editor from a helm chart as well as a ConfigMap that describes the endpoint
for the Swagger Editor. 

## Dependencies

This module uses the following terraform providers:

- `helm`
- `null`
 
## Pre-requisites

This module has the following pre-requisites in order to run:

- `kubectl` CLI must be installed
- Linux shell environment

## Example usage

```hcl-terraform
module "dev_tools_swagger_release" {
  source = "github.com/ibm-garage-cloud/garage-terraform-modules.git//generic/tools/swagger_editor?ref=v2.4.5"

  cluster_ingress_hostname = module.dev_cluster.ingress_hostname
  cluster_config_file      = module.dev_cluster.config_file_path
  tls_secret_name          = module.dev_cluster.tls_secret_name
  releases_namespace       = module.dev_cluster_namespaces.tools_namespace_name
  cluster_type             = var.cluster_type
  image_tag                = "v3.8.0"
  enable_sso               = true
  chart_version            = "1.3.0"
}
```
