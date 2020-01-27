provider "null" {
}

locals {
  tools_namespace = [var.tools_namespace]
  namespaces      = concat(local.tools_namespace, var.other_namespaces)
}

resource "null_resource" "delete_namespaces" {
  count      = length(local.namespaces)

  provisioner "local-exec" {
    command = "${path.module}/scripts/deleteNamespace.sh ${local.namespaces[count.index]}"

    environment = {
      KUBECONFIG_IKS = var.cluster_config_file_path
    }
  }
}

resource "null_resource" "create_namespaces" {
  depends_on = [null_resource.delete_namespaces]
  count      = length(local.namespaces)

  triggers = {
    namespace      = local.namespaces[count.index]
    kubeconfig_iks = var.cluster_config_file_path
  }

  provisioner "local-exec" {
    command = "${path.module}/scripts/createNamespace.sh ${self.triggers.namespace}"

    environment = {
      KUBECONFIG_IKS = self.triggers.kubeconfig_iks
    }
  }

  provisioner "local-exec" {
    when    = destroy
    command = "${path.module}/scripts/deleteNamespace.sh ${self.triggers.namespace}"

    environment = {
      KUBECONFIG_IKS = self.triggers.kubeconfig_iks
    }
  }
}

resource "null_resource" "copy_tls_secrets" {
  depends_on = [null_resource.create_namespaces]
  count      = length(local.namespaces)

  provisioner "local-exec" {
    command = "${path.module}/scripts/copy-secret-to-namespace.sh \"${var.tls_secret_name}\" ${local.namespaces[count.index]}"

    environment = {
      KUBECONFIG_IKS = var.cluster_config_file_path
    }
  }
}

resource "null_resource" "copy_apikey_secret" {
  depends_on = [null_resource.create_namespaces]
  count      = length(local.namespaces)

  provisioner "local-exec" {
    command = "${path.module}/scripts/copy-secret-to-namespace.sh ibmcloud-apikey ${local.namespaces[count.index]}"

    environment = {
      KUBECONFIG_IKS = var.cluster_config_file_path
    }
  }
}

resource "null_resource" "create_pull_secrets" {
  depends_on = [null_resource.create_namespaces]
  count      = length(local.namespaces)

  provisioner "local-exec" {
    command = "${path.module}/scripts/setup-namespace-pull-secrets.sh ${local.namespaces[count.index]}"

    environment = {
      KUBECONFIG_IKS = var.cluster_config_file_path
    }
  }
}

resource "null_resource" "copy_cloud_configmap" {
  depends_on = [null_resource.create_namespaces]
  count      = length(local.namespaces)

  provisioner "local-exec" {
    command = "${path.module}/scripts/copy-configmap-to-namespace.sh ibmcloud-config ${local.namespaces[count.index]}"

    environment = {
      KUBECONFIG_IKS = var.cluster_config_file_path
    }
  }
}
