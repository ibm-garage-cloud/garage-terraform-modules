locals {
  tmp_dir      = "${path.cwd}/.tmp"
  ingress_host = "apieditor.${var.cluster_ingress_hostname}"
  name         = "swaggereditor-dashboard"
}

resource "null_resource" "swaggereditor_release" {
  triggers = {
    namespace  = var.releases_namespace
    kubeconfig = var.cluster_config_file
    name       = local.name
  }

  provisioner "local-exec" {
    command = "${path.module}/scripts/deploy-swaggereditor.sh ${self.triggers.namespace} ${self.triggers.name} ${var.cluster_type} apieditor ${var.cluster_ingress_hostname} ${var.image_tag} ${var.enable_oauth}"

    environment = {
      KUBECONFIG_IKS  = self.triggers.kubeconfig
      TLS_SECRET_NAME = var.tls_secret_name
      TMP_DIR         = local.tmp_dir
    }
  }

  provisioner "local-exec" {
    when    = destroy
    command = "${path.module}/scripts/destroy-swaggereditor.sh ${self.triggers.namespace} ${self.triggers.name}"

    environment = {
      KUBECONFIG_IKS = self.triggers.kubeconfig
    }
  }
}
