locals {
  tmp_dir      = "${path.cwd}/.tmp"
  ingress_host = "apieditor.${var.cluster_ingress_hostname}"
}

resource "null_resource" "swaggereditor_release" {
  triggers = {
    namespace  = var.releases_namespace
    kubeconfig = var.cluster_config_file
  }

  provisioner "local-exec" {
    command = "${path.module}/scripts/deploy-swaggereditor.sh ${self.triggers.namespace} ${var.cluster_type} apieditor ${var.cluster_ingress_hostname} ${var.image_tag}"

    environment = {
      KUBECONFIG_IKS  = self.triggers.kubeconfig
      TLS_SECRET_NAME = var.tls_secret_name
      TMP_DIR         = local.tmp_dir
    }
  }

  provisioner "local-exec" {
    when    = "destroy"
    command = "${path.module}/scripts/destroy-swaggereditor.sh ${self.triggers.namespace}"

    environment = {
      KUBECONFIG_IKS = self.triggers.kubeconfig
    }
  }
}
