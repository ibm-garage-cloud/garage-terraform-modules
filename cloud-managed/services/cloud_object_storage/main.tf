data "ibm_resource_group" "tools_resource_group" {
  name = var.resource_group_name
}

locals {
  role            = "Manager"
  name_prefix     = var.name_prefix != "" ? var.name_prefix : var.resource_group_name
}

// COS Cloud Object Storage
resource "ibm_resource_instance" "cos_instance" {
  name              = "${replace(local.name_prefix, "/[^a-zA-Z0-9_\\-\\.]/", "")}-cos"
  service           = "cloud-object-storage"
  plan              = var.plan
  location          = "global"
  resource_group_id = data.ibm_resource_group.tools_resource_group.id
  tags              = var.tags

  timeouts {
    create = "15m"
    update = "15m"
    delete = "15m"
  }
}

resource "ibm_resource_key" "cos_credentials" {
  name                 = "${ibm_resource_instance.cos_instance.name}-key"
  role                 = local.role
  resource_instance_id = ibm_resource_instance.cos_instance.id

  //User can increase timeouts
  timeouts {
    create = "15m"
    delete = "15m"
  }
}

resource "ibm_container_bind_service" "cos_binding" {
  count      = var.namespace_count

  cluster_name_id             = var.cluster_id
  service_instance_name       = ibm_resource_instance.cos_instance.name
  namespace_id                = var.namespaces[count.index]
  resource_group_id           = data.ibm_resource_group.tools_resource_group.id
  key                         = ibm_resource_key.cos_credentials.name

  // The provider (v16.1) is incorrectly registering that these values change each time,
  // this may be removed in the future if this is fixed.
  lifecycle {
    ignore_changes = ["id", "namespace_id", "service_instance_name"]
  }
}
