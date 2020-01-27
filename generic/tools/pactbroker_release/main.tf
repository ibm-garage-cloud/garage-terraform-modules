locals {
  tmp_dir       = "${path.cwd}/.tmp"
  chart         = "${path.module}/charts/pact-broker"
  ingress_host  = "pact.${var.cluster_ingress_hostname}"
  ingress_url   = "http://${local.ingress_host}"
  database_type = "sqlite"
  database_name = "pactbroker.sqlite"
  secret_name   = "pactbroker-access"
  config_name   = "pactbroker-config"
  cluster_type  = var.cluster_type == "kubernetes" ? "kubernetes" : "openshift"
}

resource "null_resource" "pactbroker_release" {
  triggers = {
    kubeconfig_iks     = var.cluster_config_file
    releases_namespace = var.releases_namespace
  }

  provisioner "local-exec" {
    command = "${path.module}/scripts/deploy-pactbroker.sh ${local.chart} ${self.triggers.releases_namespace} ${local.ingress_host} ${local.database_type} ${local.database_name} ${var.tls_secret_name}"

    environment = {
      KUBECONFIG_IKS = self.triggers.kubeconfig_iks
      TMP_DIR        = local.tmp_dir
      CLUSTER_TYPE   = local.cluster_type
    }
  }

  provisioner "local-exec" {
    when    = destroy
    command = "${path.module}/scripts/destroy-pactbroker.sh ${self.triggers.releases_namespace}"

    environment = {
      KUBECONFIG_IKS = self.triggers.kubeconfig_iks
    }
  }
}
