
locals {
  operator_namespace = var.cluster_type == "ocp4" ? "openshift-marketplace" : "olm"
}

resource "null_resource" "deploy_operator_lifecycle_manager" {
  provisioner "local-exec" {
    command = "${path.module}/scripts/deploy-olm.sh ${var.olm_version}"

    environment = {
      KUBECONFIG_IKS  = var.cluster_config_file
      CLUSTER_TYPE    = var.cluster_type
    }
  }
}
