locals {
  short_name         = "cos"
  name_prefix        = var.name_prefix != "" ? var.name_prefix : var.resource_group_name
  service_name       = "${replace(local.name_prefix, "/[^a-zA-Z0-9_\\-\\.]/", "")}-${local.short_name}"
  service_class      = "cloud-object-storage"
  binding_name       = "binding-${local.short_name}"
  binding_namespaces = jsonencode(var.namespaces)
  location           = "global"
  role               = "Manager"
}

resource "null_resource" "deploy_cloud_object_store" {
  triggers = {
    service_name      = local.service_name
    service_namespace = var.service_namespace
  }

  provisioner "local-exec" {
    command = "${path.module}/scripts/deploy-service.sh ${self.triggers.service_name} ${self.triggers.service_namespace} ${var.plan} ${local.service_class} ${local.binding_name} ${local.binding_namespaces}"

    environment={
      KUBECONFIG_IKS = var.cluster_config_file
      REGION         = local.location
      RESOURCE_GROUP = var.resource_group_name
      TMP_DIR        = "${path.cwd}/.tmp"
    }
  }

  provisioner "local-exec" {
    when    = destroy
    command = "${path.module}/scripts/destroy-service.sh ${self.triggers.service_name} ${self.triggers.service_namespace}"
  }
}
