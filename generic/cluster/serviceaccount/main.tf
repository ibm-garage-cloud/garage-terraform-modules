provider "kubernetes" {

}
provider "null" {}
provider "local" {}

locals {
  tmp_dir   = "${path.cwd}/.tmp"
  name_file = "${local.tmp_dir}/${var.service_account_name}.out"
}

resource "null_resource" "delete_namespace" {
  count  = var.create_namespace ? 1 : 0

  provisioner "local-exec" {
    command = "kubectl delete namespace ${var.namespace} --wait > 1> /dev/null 2> /dev/null || exit 0"

    environment={
      KUBECONFIG_IKS = var.cluster_config_file_path
    }
  }
}

resource "kubernetes_namespace" "create" {
  depends_on = [null_resource.delete_namespace]
  count      = var.create_namespace ? 1 : 0

  metadata {
    name = var.namespace
  }
}

resource "null_resource" "delete_serviceaccount" {
  depends_on = [kubernetes_namespace.create]

  provisioner "local-exec" {
    command = "kubectl delete serviceaccount -n ${var.namespace} ${var.service_account_name} 1> /dev/null 2> /dev/null || exit 0"

    environment={
      KUBECONFIG_IKS = var.cluster_config_file_path
    }
  }
}

resource "kubernetes_service_account" "create" {
  depends_on = [null_resource.delete_serviceaccount]

  metadata {
    name      = var.service_account_name
    namespace = kubernetes_namespace.create.metadata.0.name
  }
}

resource "null_resource" "add_ssc_openshift" {
  count = var.cluster_type != "kubernetes" ? 1 : 0

  provisioner "local-exec" {
    command = "${path.module}/scripts/add-sccs-to-user.sh ${jsonencode(var.sscs)}"

    environment={
      SERVICE_ACCOUNT_NAME = kubernetes_service_account.create.metadata.0.name
      NAMESPACE            = kubernetes_service_account.create.metadata.0.namespace
    }
  }
}
