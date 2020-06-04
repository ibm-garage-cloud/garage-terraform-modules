# IBM Garage terraform modules

This repository contains a collection of terraform modules that
can be used to provision an environment in an IBM Cloud or OpenShift
environment.

The modules have been organized into three major categories:
- **cloud_managed** - modules to provision and manage resources in the IBM Cloud environment (clusters, services, etc)
- **generic** - modules that are not specific to any one environment, typically working with kubernetes resources
- **self_managed** - modules that provision/work with self_managed environments (CRC, other non-IBM Cloud managed clusters, in-cluster software, etc)

## Module catalog

### IBM provider

- *IBM Cloud Cluster* - https://github.com/ibm-garage-cloud/terraform-ibm-container-platform.git
- *AppId* - cloud-managed/services/appid
- *Cloud Object Storage* - cloud-managed/services/cloud_object_storage
- *Cloudant* - cloud-managed/services/cloudant
- *LogDNA* - https://github.com/ibm-garage-cloud/terraform-ibm-logdna.git
- *PostGreSQL* - cloud-managed/services/postgres
- *SysDig* - https://github.com/ibm-garage-cloud/terraform-ibm-sysdig.git
- *Watson Assistant* - https://github.com/ibm-garage-cloud/terraform-ibm-watson-assistant.git
- *Watson Studio* - https://github.com/ibm-garage-cloud/terraform-ibm-watson-studio.git
- *AppId operator* - cloud-managed/operator-services/appid
- *Cloud Object Storage operator* - cloud-managed/operator-services/cloud_object_storage
- *Cloudant operator* - cloud-managed/operator-services/cloudant
- *LogDNA operator* - cloud-managed/operator-services/logdna
- *PostGreSQL operator* - cloud-managed/operator-services/postgres
- *SysDig operator* - cloud-managed/operator-services/sysdig

### K8s provider

- *Namespace* - https://github.com/ibm-garage-cloud/terraform-cluster-namespace.git
- *Service Account* - https://github.com/ibm-garage-cloud/terraform-cluster-serviceaccount.git
- *Operator Lifecycle Manager* - https://github.com/ibm-garage-cloud/terraform-software-olm.git
- *Cloud Operator* - self-managed/software/cloud_operator
- *ArgoCD* - https://github.com/ibm-garage-cloud/terraform-tools-argocd.git
- *Artifactory* - https://github.com/ibm-garage-cloud/terraform-tools-artifactory.git
- *Developer Dashboard* - https://github.com/ibm-garage-cloud/terraform-tools-dashboard.git
- *Jaeger* - https://github.com/ibm-garage-cloud/terraform-tools-jaeger.git
- *Jenkins* - https://github.com/ibm-garage-cloud/terraform-tools-jenkins.git
- *Kafka* - https://github.com/ibm-garage-cloud/terraform-software-kafka.git
- *Nexus* - https://github.com/ibm-garage-cloud/terraform-tools-nexus.git
- *Pact Broker* - https://github.com/ibm-garage-cloud/terraform-tools-pactbroker.git
- *Prometheus Grafana* - generic/tools/prometheusgrafana_release
- *SonarQube* - https://github.com/ibm-garage-cloud/terraform-tools-sonarqube.git
- *Swagger Editor* - https://github.com/ibm-garage-cloud/terraform-tools-swaggereditor.git
- *Tekton* - https://github.com/ibm-garage-cloud/terraform-tools-tekton.git
- *Tekton Resources* - https://github.com/ibm-garage-cloud/terraform-tools-tekton-resources.git

## How to apply a module

In order to use one of these modules, a terraform script should be created that references the desired module(s). For example, to use the `ibmcloud_cluster` module to provision a cluster, the following would be required:

```
module "CLUSTER_NAME" {
  source = "github.com/ibm-garage-cloud/garage-terraform-modules/cluster/ibmcloud_cluster"

  resource_group_name     = "${var.resource_group_name}"
  cluster_name            = "${var.cluster_name}"
  private_vlan_id         = "${var.private_vlan_id}"
  public_vlan_id          = "${var.public_vlan_id}"
  vlan_datacenter         = "${var.vlan_datacenter}"
  cluster_region          = "${var.vlan_region}"
  kubeconfig_download_dir = "${var.user_home_dir}"
  cluster_machine_type    = "${var.cluster_machine_type}"
  cluster_worker_count    = "${var.cluster_worker_count}"
  cluster_hardware        = "${var.cluster_hardware}"
  cluster_type            = "${var.cluster_type}"
  cluster_exists          = "${var.cluster_exists}"
  ibmcloud_api_key        = "${var.ibmcloud_api_key}"
}
```

where:
- `CLUSTER_NAME` is any name you want for your terraform script
- `source` points to the module folder in this repo
- `${var.xxx}` refers to a variable in your terraform script. All of the variables defined within the module's `variables.tf` file need to be provided a value, either through the terraform script or through a default value in the variables.tf file itself

**Note:** If you want to refer to a specific version of a module identified by a branch or tag within the repo, you can add `ref` to the end of the repo url. E.g. github.com/ibm-garage-cloud/garage-terraform-modules/cluster/ibmcloud_cluster?ref=v1.0.0

For more information on Terraform modules see https://www.terraform.io/docs/modules/index.html

## Contribution

We want the broader Garage teams to contribute to this work to help scale and grow skills and accelerate projects.

Read the following contribution guidelines to help support the work.

- [Governance Process](./governance.md)
- [Developer Contribution](./developer_contribution.md)

```
Current Release : 2.0.6
```


