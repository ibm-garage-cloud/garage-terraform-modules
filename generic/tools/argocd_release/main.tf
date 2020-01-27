locals {
  tmp_dir      = "${path.cwd}/.tmp"
  chart_name   = "argo-cd"
  enable_cache = var.enable_cache
  ingress_host = "argocd.${var.cluster_ingress_hostname}"
  ingress_subdomain = var.cluster_ingress_hostname
  ingress_url  = "http://${local.ingress_host}"
  config_name  = "argocd-config"
  secret_name  = "argocd-access"
}

resource "null_resource" "argocd_release" {
  triggers = {
    kubeconfig_iks     = var.cluster_config_file
    releases_namespace = var.releases_namespace
  }

  provisioner "local-exec" {
    command = "${path.module}/scripts/deploy-argocd.sh ${local.chart_name} ${self.triggers.releases_namespace} ${var.helm_version} ${local.ingress_host} ${local.ingress_subdomain} ${local.enable_cache}"

    environment = {
      KUBECONFIG_IKS  = self.triggers.kubeconfig_iks
      CLUSTER_TYPE    = var.cluster_type
      TLS_SECRET_NAME = var.tls_secret_name
      TMP_DIR         = local.tmp_dir
    }
  }

  provisioner "local-exec" {
    when    = destroy
    command = "${path.module}/scripts/destroy-argocd.sh ${self.triggers.releases_namespace}"

    environment = {
      KUBECONFIG_IKS = self.triggers.kubeconfig_iks
    }
  }
}
