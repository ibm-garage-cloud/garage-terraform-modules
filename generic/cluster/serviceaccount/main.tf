provider "kubernetes" {
  config_path = var.cluster_config_file_path
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
    command = "kubectl delete namespace ${var.namespace} --wait=true 1> /dev/null 2> /dev/null || exit 0"

    environment={
      KUBECONFIG = var.cluster_config_file_path
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
    command = "kubectl delete serviceaccount -n ${var.namespace} ${var.service_account_name} --wait=true 1> /dev/null 2> /dev/null || exit 0"

    environment={
      KUBECONFIG = var.cluster_config_file_path
    }
  }
}

resource "kubernetes_service_account" "create" {
  depends_on = [null_resource.delete_serviceaccount]

  metadata {
    name      = var.service_account_name
    namespace = var.namespace
  }
}

resource "null_resource" "add_ssc_openshift" {
  depends_on = [kubernetes_service_account.create]
  count      = var.cluster_type != "kubernetes" ? 1 : 0

  provisioner "local-exec" {
    command = "${path.module}/scripts/add-sccs-to-user.sh ${jsonencode(var.sscs)}"

    environment={
      SERVICE_ACCOUNT_NAME = var.service_account_name
      NAMESPACE            = var.namespace
    }
  }
}
