locals {
  tmp_dir            = "${path.cwd}/.tmp"
  short_name         = "logdna"
  namespaces         = [var.namespace]
  name_prefix        = var.name_prefix != "" ? var.name_prefix : var.resource_group_name
  service_name       = "${replace(local.name_prefix, "/[^a-zA-Z0-9_\\-\\.]/", "")}-${local.short_name}"
  service_class      = "logdna"
  binding_name       = "binding-${local.short_name}"
  binding_namespaces = jsonencode(local.namespaces)
  resource_location  = var.resource_location == "us-east" ? "us-south" : var.resource_location
  role               = "Manager"
  credentials_file   = "${local.tmp_dir}/logdna_credentials.json"
  ingestion_key_file = "${local.tmp_dir}/logdna_injestion_key.val"
}

resource "null_resource" "deploy_logdna" {
  triggers = {
    service_name      = local.service_name
    service_namespace = var.service_namespace
  }

  provisioner "local-exec" {
    command = "${path.module}/scripts/deploy-service.sh ${self.triggers.service_name} ${self.triggers.service_namespace} ${var.plan} ${local.service_class} ${local.binding_name} ${local.binding_namespaces} ${var.namespace}"

    environment={
      KUBECONFIG_IKS = var.cluster_config_file_path
      REGION         = local.resource_location
      RESOURCE_GROUP = var.resource_group_name
      TMP_DIR        = local.tmp_dir
    }
  }

  provisioner "local-exec" {
    when    = destroy
    command = "${path.module}/scripts/destroy-service.sh ${self.triggers.service_name} ${self.triggers.service_namespace}"
  }
}

resource "null_resource" "create_tmp" {
  provisioner "local-exec" {
    command = "mkdir -p ${local.tmp_dir}"
  }
}

resource "null_resource" "write_ingestion_key" {
  depends_on = [
    null_resource.deploy_logdna,
    null_resource.create_tmp,
  ]

  provisioner "local-exec" {
    command = "${path.module}/scripts/get-secret-value.sh ${local.binding_name} ${var.namespace} ingestion_key > ${local.ingestion_key_file}"

    environment={
      KUBECONFIG_IKS = var.cluster_config_file_path
    }
  }
}

data "local_file" "injestion_key" {
  depends_on = [null_resource.write_ingestion_key]

  filename = local.ingestion_key_file
}

resource "null_resource" "logdna_bind" {
  triggers = {
    kubeconfig = var.cluster_config_file_path
  }
  provisioner "local-exec" {
    command = "${path.module}/scripts/bind-logdna.sh ${var.cluster_type} ${data.local_file.injestion_key.content} ${local.resource_location} ${var.bind_script_version}"

    environment = {
      KUBECONFIG_IKS = self.triggers.kubeconfig
      TMP_DIR        = local.tmp_dir
    }
  }

  provisioner "local-exec" {
    when    = destroy
    command = "${path.module}/scripts/unbind-logdna.sh"

    environment = {
      KUBECONFIG_IKS = self.triggers.kubeconfig
    }
  }
}
