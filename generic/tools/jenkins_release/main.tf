provider "null" {
}

locals {
  tmp_dir               = "${path.cwd}/.tmp"
  secret_name           = "jenkins-access"
  config_name           = "jenkins-config"
  ingress_host          = "jenkins.${var.cluster_ingress_hostname}"
  ingress_url           = "${var.cluster_type != "kubernetes" ? "https" : "http"}://${local.ingress_host}"
}

resource "null_resource" "jenkins_release_iks" {
  count = var.cluster_type == "kubernetes" ? 1 : 0

  triggers = {
    kubeconfig         = var.cluster_config_file
    releases_namespace = var.releases_namespace
  }

  provisioner "local-exec" {
    command = "${path.module}/scripts/deploy-jenkins.sh ${self.triggers.releases_namespace} ${local.ingress_host} ${var.helm_version} ${var.tls_secret_name}"

    environment = {
      KUBECONFIG    = self.triggers.kubeconfig
      STORAGE_CLASS = var.storage_class
      TMP_DIR       = local.tmp_dir
      EXCLUDE_POD_NAME = "deploy"
    }
  }

  provisioner "local-exec" {
    when    = destroy
    command = "${path.module}/scripts/destroy-jenkins.sh ${self.triggers.releases_namespace}"

    environment = {
      KUBECONFIG_IKS = self.triggers.kubeconfig
    }
  }
}

resource "null_resource" "jenkins_release_openshift" {
  count = var.cluster_type != "kubernetes" ? 1 : 0

  triggers = {
    releases_namespace = var.releases_namespace
  }

  provisioner "local-exec" {
    command = "${path.module}/scripts/deploy-jenkins-openshift.sh ${self.triggers.releases_namespace} ${var.volume_capacity} ${var.storage_class}"

    environment = {
      TMP_DIR    = local.tmp_dir
      SERVER_URL = var.server_url
    }
  }

  provisioner "local-exec" {
    when    = destroy
    command = "${path.module}/scripts/destroy-jenkins.sh ${self.triggers.releases_namespace}"
  }
}
