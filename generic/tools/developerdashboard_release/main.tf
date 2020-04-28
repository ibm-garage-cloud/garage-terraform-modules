locals {
  tmp_dir      = "${path.cwd}/.tmp"
}

resource "null_resource" "catalystdashboard_release" {
  triggers = {
    kubeconfig_iks     = var.cluster_config_file
    releases_namespace = var.releases_namespace
    cluster_type       = var.cluster_type
  }

  provisioner "local-exec" {
    command = "${path.module}/scripts/deploy-dashboard.sh ${self.triggers.releases_namespace} ${self.triggers.cluster_type} dashboard ${var.cluster_ingress_hostname} ${var.chart_version} ${var.enable_sso}"

    environment = {
      KUBECONFIG  = self.triggers.kubeconfig_iks
      TLS_SECRET_NAME = var.tls_secret_name
      TMP_DIR         = local.tmp_dir
    }
  }

  provisioner "local-exec" {
    when    = destroy
    command = "${path.module}/scripts/destroy-dashboard.sh ${self.triggers.releases_namespace} ${self.triggers.cluster_type}"

    environment = {
      KUBECONFIG = self.triggers.kubeconfig_iks
    }
  }
}
