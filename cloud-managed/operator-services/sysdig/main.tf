locals {
//  access_key  = "${ibm_resource_key.sysdig_instance_key.credentials["Sysdig Access Key"]}"
//  endpoint    = "${ibm_resource_key.sysdig_instance_key.credentials["Sysdig Collector Endpoint"]}"
  tmp_dir            = "${path.cwd}/.tmp"
  short_name         = "sysdig"
  namespaces         = [var.tools_namespace]
  name_prefix        = var.name_prefix != "" ? var.name_prefix : var.resource_group_name
  service_name       = "${replace(local.name_prefix, "/[^a-zA-Z0-9_\\-\\.]/", "")}-${local.short_name}"
  service_class      = "sysdig-monitor"
  binding_name       = "binding-${local.short_name}"
  binding_namespaces = jsonencode(local.namespaces)
  role               = "Manager"
  credentials_file   = "${local.tmp_dir}/sysdig_credentials.json"
  access_key_file    = "${local.tmp_dir}/sysdig_access_key.val"
  endpoint_file      = "${local.tmp_dir}/sysdig_endpoint.val"
}

resource "null_resource" "deploy_sysdig" {
  triggers = {
    service_name      = local.service_name
    service_namespace = var.service_namespace
  }

  provisioner "local-exec" {
    command = "${path.module}/scripts/deploy-service.sh ${self.triggers.service_name} ${self.triggers.service_namespace} ${var.plan} ${local.service_class} ${local.binding_name} ${local.binding_namespaces} ${var.tools_namespace}"

    environment={
      KUBECONFIG_IKS = var.cluster_config_file_path
      REGION         = var.resource_location
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

resource "null_resource" "write_access_key" {
  depends_on = [
    null_resource.deploy_sysdig,
    null_resource.create_tmp,
  ]

  provisioner "local-exec" {
    command = "${path.module}/scripts/get-secret-value.sh ${local.binding_name} ${var.tools_namespace} Sysdig_Access_Key > ${local.access_key_file}"

    environment={
      KUBECONFIG_IKS = var.cluster_config_file_path
    }
  }
}

resource "null_resource" "write_endpoint" {
  depends_on = [
    null_resource.deploy_sysdig,
    null_resource.create_tmp,
  ]

  provisioner "local-exec" {
    command = "${path.module}/scripts/get-secret-value.sh ${local.binding_name} ${var.tools_namespace} Sysdig_Collector_Endpoint > ${local.endpoint_file}"

    environment={
      KUBECONFIG_IKS = var.cluster_config_file_path
    }
  }
}

data "local_file" "access_key" {
  depends_on = [null_resource.write_access_key]

  filename = local.access_key_file
}

data "local_file" "endpoint" {
  depends_on = [null_resource.write_endpoint]

  filename = local.endpoint_file
}

resource "null_resource" "create_sysdig_agent" {
  triggers = {
    kubeconfig_iks = var.cluster_config_file_path
  }

  provisioner "local-exec" {
    command = "${path.module}/scripts/bind-sysdig.sh ${data.local_file.access_key.content} ${data.local_file.endpoint.content}"

    environment = {
      KUBECONFIG_IKS = self.triggers.kubeconfig_iks
    }
  }

  provisioner "local-exec" {
    when    = destroy
    command = "${path.module}/scripts/unbind-sysdig.sh"

    environment = {
      KUBECONFIG_IKS = self.triggers.kubeconfig_iks
    }
  }
}
