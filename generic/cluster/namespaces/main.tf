resource "null_resource" "print_kube_config" {
  provisioner "local-exec" {
    command = "echo \"path=${var.cluster_config_path}, file=${var.cluster_config_file_path}\""
  }
}
provider "null" {}

locals {
  tools_namespace = [var.tools_namespace]
  namespaces      = concat(local.tools_namespace, var.release_namespaces)
}

resource "null_resource" "delete_tools_namespace" {
  provisioner "local-exec" {
    command = "${path.module}/scripts/deleteNamespace.sh ${var.tools_namespace}"

    environment = {
      KUBECONFIG_IKS = var.cluster_config_file_path
    }
  }
}

resource "null_resource" "delete_release_namespaces" {
  count      = length(var.release_namespaces)

  provisioner "local-exec" {
    command = "${path.module}/scripts/deleteNamespace.sh ${var.release_namespaces[count.index]}"

    environment = {
      KUBECONFIG_IKS = var.cluster_config_file_path
    }
  }
}

resource "kubernetes_namespace" "tools" {
  depends_on = [null_resource.delete_tools_namespace]

  metadata {
    name = var.tools_namespace
  }
}
//
//resource "null_resource" "create_tools_namespace" {
//  depends_on = [null_resource.delete_tools_namespace]
//
//  triggers = {
//    namespace      = var.tools_namespace
//    kubeconfig_iks = var.cluster_config_file_path
//  }
//
//  provisioner "local-exec" {
//    command = "${path.module}/scripts/createNamespace.sh ${self.triggers.namespace}"
//
//    environment = {
//      KUBECONFIG_IKS = self.triggers.kubeconfig_iks
//    }
//  }
//
//  provisioner "local-exec" {
//    when    = destroy
//    command = "${path.module}/scripts/deleteNamespace.sh ${self.triggers.namespace}"
//
//    environment = {
//      KUBECONFIG_IKS = self.triggers.kubeconfig_iks
//    }
//  }
//}


resource "kubernetes_namespace" "releases" {
  depends_on = [null_resource.delete_release_namespaces]
  count      = length(var.release_namespaces)

  metadata {
    name = var.release_namespaces[count.index]
  }
}
//
//resource "null_resource" "create_release_namespaces" {
//  depends_on = [null_resource.delete_release_namespaces]
//  count      = length(var.release_namespaces)
//
//  triggers = {
//    namespace      = var.release_namespaces[count.index]
//    kubeconfig_iks = var.cluster_config_file_path
//  }
//
//  provisioner "local-exec" {
//    command = "${path.module}/scripts/createNamespace.sh ${self.triggers.namespace}"
//
//    environment = {
//      KUBECONFIG_IKS = self.triggers.kubeconfig_iks
//    }
//  }
//
//  provisioner "local-exec" {
//    when    = destroy
//    command = "${path.module}/scripts/deleteNamespace.sh ${self.triggers.namespace}"
//
//    environment = {
//      KUBECONFIG_IKS = self.triggers.kubeconfig_iks
//    }
//  }
//}

resource "null_resource" "copy_tls_secrets" {
  depends_on = [kubernetes_namespace.tools, kubernetes_namespace.releases]
  count      = length(local.namespaces)

  provisioner "local-exec" {
    command = "${path.module}/scripts/copy-secret-to-namespace.sh \"${var.tls_secret_name}\" ${local.namespaces[count.index]}"

    environment = {
      KUBECONFIG_IKS = var.cluster_config_file_path
    }
  }
}

resource "null_resource" "copy_apikey_secret" {
  depends_on = [kubernetes_namespace.tools, kubernetes_namespace.releases]
  count      = length(local.namespaces)

  provisioner "local-exec" {
    command = "${path.module}/scripts/copy-secret-to-namespace.sh ibmcloud-apikey ${local.namespaces[count.index]}"

    environment = {
      KUBECONFIG_IKS = var.cluster_config_file_path
    }
  }
}

resource "null_resource" "create_pull_secrets" {
  depends_on = [kubernetes_namespace.tools, kubernetes_namespace.releases]
  count      = length(local.namespaces)

  provisioner "local-exec" {
    command = "${path.module}/scripts/setup-namespace-pull-secrets.sh ${local.namespaces[count.index]}"

    environment = {
      KUBECONFIG_IKS = var.cluster_config_file_path
    }
  }
}

resource "null_resource" "copy_cloud_configmap" {
  depends_on = [kubernetes_namespace.tools, kubernetes_namespace.releases]
  count      = length(local.namespaces)

  provisioner "local-exec" {
    command = "${path.module}/scripts/copy-configmap-to-namespace.sh ibmcloud-config ${local.namespaces[count.index]}"

    environment = {
      KUBECONFIG_IKS = var.cluster_config_file_path
    }
  }
}
