provider "null" {
}
provider "local" {
}

locals {
  tmp_dir   = "${path.cwd}/.tmp"
  name_file = "${local.tmp_dir}/${var.service_account_name}.out"
}

resource "null_resource" "delete_serviceaccount" {

  provisioner "local-exec" {
    command = "${path.module}/scripts/delete-serviceaccount.sh ${var.namespace} ${var.service_account_name}"

    environment={
      KUBECONFIG_IKS = var.cluster_config_file_path
    }
  }
}

resource "null_resource" "create_serviceaccount" {
  depends_on = [null_resource.delete_serviceaccount]

  triggers = {
    kubeconfig_iks  = var.cluster_config_file_path
    namespace       = var.namespace
    service_account = var.service_account_name
  }

  provisioner "local-exec" {
    command = "${path.module}/scripts/create-serviceaccount.sh ${self.triggers.namespace} ${self.triggers.service_account}"

    environment={
      KUBECONFIG_IKS = self.triggers.kubeconfig_iks
    }
  }

  provisioner "local-exec" {
    when    = destroy
    command = "${path.module}/scripts/delete-serviceaccount.sh ${self.triggers.namespace} ${self.triggers.service_account}"

    environment={
      KUBECONFIG_IKS = self.triggers.kubeconfig_iks
    }
  }
}

resource "null_resource" "add_ssc_openshift" {
  depends_on = [null_resource.create_serviceaccount]
  count = var.cluster_type != "kubernetes" ? 1 : 0

  provisioner "local-exec" {
    command = "${path.module}/scripts/add-sccs-to-user.sh ${jsonencode(var.sscs)}"

    environment={
      SERVICE_ACCOUNT_NAME = var.service_account_name
      NAMESPACE            = var.namespace
    }
  }
}
