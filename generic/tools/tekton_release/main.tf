provider "null" {
}

locals {
  ingress_host = "tekton.${var.cluster_ingress_hostname}"
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

}

resource "null_resource" "tekton_dashboard" {
  depends_on = [null_resource.tekton]

  triggers = {
    kubeconfig = var.cluster_config_file_path
    dashboard_namespace = var.tekton_dashboard_namespace
    dashboard_version = var.tekton_dashboard_version
  }

  provisioner "local-exec" {
    command = "${path.module}/scripts/deploy-tekton-dashboard.sh ${local.ingress_host} ${self.triggers.dashboard_namespace} ${self.triggers.dashboard_version}"

    environment = {
      KUBECONFIG = self.triggers.kubeconfig
    }
  }

  provisioner "local-exec" {
    when    = destroy
    command = "${path.module}/scripts/destroy-tekton-dashboard.sh ${self.triggers.dashboard_namespace} ${self.triggers.dashboard_version}"

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
    dashboard_namespace = var.tekton_dashboard_namespace
  }

  provisioner "local-exec" {
    command = "${path.module}/scripts/copy-configmap-to-namespace.sh tekton-config ${self.triggers.tools_namespace}  ${self.triggers.dashboard_namespace}"

    environment = {
      KUBECONFIG = self.triggers.kubeconfig
    }
  }

  provisioner "local-exec" {
    when    = destroy
    command = "${path.module}/scripts/destroy-tekton-configmap-tools.sh tekton-config ${self.triggers.tools_namespace}"

    environment = {
      KUBECONFIG = self.triggers.kubeconfig
    }
  }
}
