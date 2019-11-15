locals {
  tmp_dir      = "${path.cwd}/.tmp"
  chart_name   = "argo-cd"
  enable_cache = "${var.enable_cache}"
  ingress_host = "argocd.${var.cluster_ingress_hostname}"
  ingress_subdomain = "${var.cluster_ingress_hostname}"
  ingress_tlssecret = "${var.tls_secret_name}"
  ingress_url  = "http://${local.ingress_host}"
  config_name  = "argocd-config"
  secret_name  = "argocd-access"
}

resource "null_resource" "argocd_release" {
  provisioner "local-exec" {
    command = "${path.module}/scripts/deploy-argocd.sh ${local.chart_name} ${var.releases_namespace} ${var.helm_version} ${local.ingress_host} ${local.ingress_subdomain} ${local.ingress_tlssecret} ${local.enable_cache}"

    environment = {
      KUBECONFIG_IKS  = "${var.cluster_config_file}"
      TLS_SECRET_NAME = "${var.tls_secret_name}"
      TMP_DIR         = "${local.tmp_dir}"
    }
  }

  provisioner "local-exec" {
    when    = "destroy"
    command = "${path.module}/scripts/destroy-argocd.sh ${var.releases_namespace}"

    environment = {
      KUBECONFIG_IKS = "${var.cluster_config_file}"
    }
  }
}
