provider "null" {
}

locals {
  cluster_config_dir    = "${var.kubeconfig_download_dir}/.kube"
  config_file_path       = "${local.cluster_config_dir}/config"
  config_namespace       = "default"
  ibmcloud_apikey_chart  = "${path.module}/charts/ibmcloud"
  cluster_name           = "crc"
  tls_secret_file        = ""
  tmp_dir                = "${path.cwd}/.tmp"
  registry_url           = "image-registry.openshift-image-registry:5000"
}

resource "null_resource" "oc_login" {
  count      = var.cluster_type != "kubernetes" ? 1: 0

  provisioner "local-exec" {
    command = "oc login --insecure-skip-tls-verify=true -u ${var.login_user} -p ${var.ibmcloud_api_key} --server=${var.server_url} > /dev/null"
  }
}

resource "null_resource" "ibmcloud_apikey_release" {
  depends_on = [null_resource.oc_login]

  provisioner "local-exec" {
    command = "${path.module}/scripts/deploy-ibmcloud-config.sh"

    environment = {
      KUBECONFIG    = local.config_file_path
      TMP_DIR           = local.tmp_dir
      CHART             = local.ibmcloud_apikey_chart
      NAMESPACE         = local.config_namespace
      APIKEY            = var.ibmcloud_api_key
      RESOURCE_GROUP    = var.resource_group_name
      SERVER_URL        = var.server_url
      CLUSTER_TYPE      = var.cluster_type
      CLUSTER_NAME      = local.cluster_name
      INGRESS_SUBDOMAIN = var.ingress_subdomain
      TLS_SECRET_FILE   = local.tls_secret_file
      TLS_SECRET_NAME   = var.tls_secret_name
      REGISTRY_URL      = local.registry_url
    }
  }
}
