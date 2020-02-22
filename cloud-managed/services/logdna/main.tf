provider "ibm" {
  version = "1.2.1"
}

provider "null" {
}

data "ibm_resource_group" "tools_resource_group" {
  name = var.resource_group_name
}

locals {
  name_prefix       = var.name_prefix != "" ? var.name_prefix : var.resource_group_name
  role              = "Manager"
  resource_location = var.resource_location
}

// LogDNA - Logging
resource "ibm_resource_instance" "logdna_instance" {
  name              = "${replace(local.name_prefix, "/[^a-zA-Z0-9_\\-\\.]/", "")}-logdna"
  service           = "logdna"
  plan              = var.plan
  location          = local.resource_location
  resource_group_id = data.ibm_resource_group.tools_resource_group.id
  tags              = var.tags

  timeouts {
    create = "15m"
    update = "15m"
    delete = "15m"
  }
}

resource "ibm_resource_key" "logdna_instance_key" {
  name                 = "${ibm_resource_instance.logdna_instance.name}-key"
  resource_instance_id = ibm_resource_instance.logdna_instance.id
  role                 = local.role

  //User can increase timeouts 
  timeouts {
    create = "15m"
    delete = "15m"
  }
}

resource "null_resource" "logdna_bind" {
  triggers = {
    namespace      = var.namespace
    kubeconfig_iks = var.cluster_config_file_path
  }

  provisioner "local-exec" {
    command = "${path.module}/scripts/bind-logdna.sh ${var.cluster_type} ${ibm_resource_key.logdna_instance_key.credentials.ingestion_key} ${local.resource_location} ${var.namespace}"

    environment = {
      KUBECONFIG_IKS = self.triggers.kubeconfig_iks
      TMP_DIR        = "${path.cwd}/.tmp"
    }
  }

  provisioner "local-exec" {
    when    = destroy
    command = "${path.module}/scripts/unbind-logdna.sh ${self.triggers.namespace}"

    environment = {
      KUBECONFIG_IKS = self.triggers.kubeconfig_iks
    }
  }
}
