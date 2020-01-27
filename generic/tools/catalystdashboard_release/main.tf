locals {
  tmp_dir      = "${path.cwd}/.tmp"
  ingress_host = "dashboard.${var.cluster_ingress_hostname}"
}

resource "null_resource" "catalystdashboard_release" {
  triggers = {
    kubeconfig_iks     = var.cluster_config_file
    releases_namespace = var.releases_namespace
  }

  provisioner "local-exec" {
    command = "${path.module}/scripts/deploy-catalystdashboard.sh ${self.triggers.releases_namespace} ${var.cluster_type} dashboard ${var.cluster_ingress_hostname} ${var.image_tag} \"${jsonencode(var.tool_config_maps)}\""

    environment = {
      KUBECONFIG_IKS  = self.triggers.kubeconfig_iks
      TLS_SECRET_NAME = var.tls_secret_name
      TMP_DIR         = local.tmp_dir
    }
  }

  provisioner "local-exec" {
    when    = destroy
    command = "${path.module}/scripts/destroy-catalystdashboard.sh ${self.triggers.releases_namespace}"

    environment = {
      KUBECONFIG_IKS = self.triggers.kubeconfig_iks
    }
  }
}
