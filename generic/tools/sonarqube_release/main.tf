provider "null" {
}

locals {
  tmp_dir                = "${path.cwd}/.tmp"
  sonarqube_secret_chart = "${path.module}/charts/sonarqube-access"
  ingress_host           = "sonarqube.${var.cluster_ingress_hostname}"
  ingress_url            = "http://${local.ingress_host}"
  secret_name            = "sonarqube-access"
  config_name            = "sonarqube-config"
  values_file_default    = "${path.module}/sonarqube-values.yaml"
  values_file_openshift  = "${path.module}/sonarqube-values-openshift.yaml"
  values_file            = "${var.cluster_type == "openshift" ? local.values_file_openshift : local.values_file_default}" 
  kustomize_template     = "${path.module}/kustomize/sonarqube"
  volume_capacity        = "${var.volume_capacity}"
}

resource "null_resource" "sonarqube_release" {
  provisioner "local-exec" {
    command = "${path.module}/scripts/deploy-sonarqube.sh ${local.sonarqube_secret_chart} ${var.releases_namespace} ${local.ingress_host} ${local.values_file} ${local.kustomize_template} ${var.helm_version} ${var.service_account_name} \"${jsonencode(var.plugins)}\" ${local.volume_capacity} ${var.tls_secret_name}"

    environment = {
      KUBECONFIG_IKS    = "${var.cluster_config_file}"
      TMP_DIR           = "${local.tmp_dir}"
      DATABASE_HOST     = "${var.postgresql_hostname}"
      DATABASE_PORT     = "${var.postgresql_port}"
      DATABASE_NAME     = "${var.postgresql_database_name}"
      DATABASE_USERNAME = "${var.postgresql_username}"
      DATABASE_PASSWORD = "${var.postgresql_password}"
    }
  }

  provisioner "local-exec" {
    when    = "destroy"
    command = "${path.module}/scripts/destroy-sonarqube.sh ${var.releases_namespace}"

    environment = {
      KUBECONFIG_IKS = "${var.cluster_config_file}"
    }
  }
}
