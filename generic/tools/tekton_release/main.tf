provider "null" {
}

locals {
  ingress_host = "tekton.${var.cluster_ingress_hostname}"
  namespace    = "tekton-pipelines"
}

resource "null_resource" "tekton" {

  triggers = {
    kubeconfig = var.cluster_config_file_path
  }
  
  provisioner "local-exec" {
    command = "${path.module}/scripts/deploy-tekton.sh"

    environment = {
      KUBECONFIG = self.triggers.kubeconfig
    }
  }

  provisioner "local-exec" {
    when    = destroy
    command = "${path.module}/scripts/destroy-tekton.sh"

    environment = {
      KUBECONFIG = self.triggers.kubeconfig
    }
  }
}

resource "null_resource" "tekton_dashboard" {
  depends_on = [null_resource.tekton]

  triggers = {
    kubeconfig = var.cluster_config_file_path
  }

  provisioner "local-exec" {
    command = "${path.module}/scripts/deploy-tekton-dashboard.sh ${local.ingress_host} ${local.namespace}"

    environment = {
      KUBECONFIG = self.triggers.kubeconfig
    }
  }

  provisioner "local-exec" {
    when    = destroy
    command = "${path.module}/scripts/destroy-tekton-dashboard.sh ${local.namespace}"

    environment = {
      KUBECONFIG = self.triggers.kubeconfig
    }
  }
}

resource "null_resource" "copy_cloud_configmap" {
  depends_on = [null_resource.tekton_dashboard]

  triggers = {
    kubeconfig         = var.cluster_config_file_path
    tools_namespace    = var.tools_namespace
  }

  provisioner "local-exec" {
    command = "${path.module}/scripts/copy-configmap-to-namespace.sh tekton-config ${self.triggers.tools_namespace} ${local.namespace}"

    environment = {
      KUBECONFIG = self.triggers.kubeconfig
    }
  }

  provisioner "local-exec" {
    when    = destroy
    command = "${path.module}/scripts/destroy-configmap.sh tekton-config ${self.triggers.tools_namespace}"

    environment = {
      KUBECONFIG = self.triggers.kubeconfig
    }
  }
}
