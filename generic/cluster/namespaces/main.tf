provider "kubernetes" {
  config_path = var.cluster_config_file_path
}
provider "null" {}

locals {
  tools_namespace = [var.tools_namespace]
  namespaces      = concat(local.tools_namespace, var.release_namespaces)
}

resource "null_resource" "delete_tools_namespace" {
  provisioner "local-exec" {
    command = "kubectl delete namespace ${var.tools_namespace} --wait || exit 0"

    environment = {
      KUBECONFIG = var.cluster_config_file_path
    }
  }
}

resource "null_resource" "delete_release_namespaces" {
  count      = length(var.release_namespaces)

  provisioner "local-exec" {
    command = "kubectl delete namespace ${var.release_namespaces[count.index]} --wait || exit 0"

    environment = {
      KUBECONFIG = var.cluster_config_file_path
    }
  }
}

resource "kubernetes_namespace" "tools" {
  depends_on = [null_resource.delete_tools_namespace]

  metadata {
    name = var.tools_namespace
  }
}

resource "kubernetes_namespace" "releases" {
  depends_on = [null_resource.delete_release_namespaces]
  count      = length(var.release_namespaces)

  metadata {
    name = var.release_namespaces[count.index]
  }
}

resource "null_resource" "copy_apikey_secret" {
  depends_on = [kubernetes_namespace.tools, kubernetes_namespace.releases]
  count      = length(local.namespaces)

  provisioner "local-exec" {
    command = "${path.module}/scripts/copy-secret-to-namespace.sh ibmcloud-apikey ${local.namespaces[count.index]}"

    environment = {
      KUBECONFIG = var.cluster_config_file_path
    }
  }
}

resource "null_resource" "create_pull_secrets" {
  depends_on = [kubernetes_namespace.tools, kubernetes_namespace.releases]
  count      = length(local.namespaces)

  provisioner "local-exec" {
    command = "${path.module}/scripts/setup-namespace-pull-secrets.sh ${local.namespaces[count.index]}"

    environment = {
      KUBECONFIG = var.cluster_config_file_path
    }
  }
}

resource "null_resource" "copy_cloud_configmap" {
  depends_on = [kubernetes_namespace.tools, kubernetes_namespace.releases]
  count      = length(local.namespaces)

  provisioner "local-exec" {
    command = "${path.module}/scripts/copy-configmap-to-namespace.sh ibmcloud-config ${local.namespaces[count.index]}"

    environment = {
      KUBECONFIG = var.cluster_config_file_path
    }
  }
}
