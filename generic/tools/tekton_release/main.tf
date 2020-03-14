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
    cluster_type = var.cluster_type
    dashboard_namespace = var.tekton_dashboard_namespace
    dashboard_version = var.tekton_dashboard_version
    dashboard_yaml_file_ocp = var.tekton_dashboard_yaml_file_ocp
    dashboard_yaml_file_k8s = var.tekton_dashboard_yaml_file_k8s
  }

  provisioner "local-exec" {
    command = "${path.module}/scripts/deploy-tekton-dashboard.sh ${self.triggers.dashboard_namespace} ${self.triggers.dashboard_version} ${self.triggers.cluster_type} ${self.triggers.dashboard_yaml_file_k8s} ${self.triggers.dashboard_yaml_file_ocp} ${local.ingress_host}"

    environment = {
      KUBECONFIG = self.triggers.kubeconfig
    }
  }

  provisioner "local-exec" {
    when    = destroy
    command = "${path.module}/scripts/destroy-tekton-dashboard.sh ${self.triggers.dashboard_namespace} ${self.triggers.dashboard_version} ${self.triggers.cluster_type} ${self.triggers.dashboard_yaml_file_k8s} ${self.triggers.dashboard_yaml_file_ocp}"

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
