provider "null" {
}

locals {
  ingress_host          = "tekton.${var.cluster_ingress_hostname}"
}


resource "null_resource" "tekton_sub" {
  provisioner "local-exec" {
    command = "${path.module}/scripts/deploy-tekton.sh"

    environment = {
      KUBECONFIG_IKS = "${var.cluster_config_file_path}"
    }
  }
}


resource "null_resource" "tekton_dashboard" {
    depends_on = ["null_resource.tekton_sub"]
  provisioner "local-exec" {
    command = "${path.module}/scripts/deploy-tekton-dashboard.sh"

    environment = {
      KUBECONFIG_IKS = "${var.cluster_config_file_path}"
      INGRESS_HOST = "${local.ingress_host}"
    }
  }
}

resource "null_resource" "copy_cloud_configmap" {
  depends_on = ["null_resource.tekton_dashboard"]

  provisioner "local-exec" {
    command = "${path.module}/scripts/copy-configmap-to-namespace.sh tekton-config tools tekton-pipelines"

    environment = {
      KUBECONFIG_IKS = "${var.cluster_config_file_path}"
    }
  }
}
