locals {
  tmp_dir                = "${path.cwd}/.tmp"
  ingress_host           = "artifactory.${var.cluster_ingress_hostname}"
  ingress_url            = "http://${local.ingress_host}"
  values_file            = "${path.module}/artifactory-values.yaml"
  config_name            = "artifactory-config"
  secret_name            = "artifactory-access"
}

resource "null_resource" "artifactory_release" {
  triggers = {
    kubeconfig_iks     = var.cluster_config_file
    releases_namespace = var.releases_namespace
  }

  provisioner "local-exec" {
    command = "${path.module}/scripts/deploy-artifactory.sh ${self.triggers.releases_namespace} ${local.ingress_host} ${local.values_file} ${var.chart_version} ${var.service_account} ${var.tls_secret_name}"

    environment = {
      KUBECONFIG_IKS = self.triggers.kubeconfig_iks
      STORAGE_CLASS  = var.storage_class
      TMP_DIR        = local.tmp_dir
      CLUSTER_TYPE   = var.cluster_type
    }
  }

  provisioner "local-exec" {
    when    = destroy
    command = "${path.module}/scripts/destroy-artifactory.sh ${self.triggers.releases_namespace}"

    environment = {
      KUBECONFIG_IKS = self.triggers.kubeconfig_iks
    }
  }
}
