provider "ibm" {
  version=">= 1.2.1"
}

data "ibm_resource_group" "tools_resource_group" {
  name = var.resource_group_name
}

locals {
  role             = "Administrator"
  name_prefix      = var.name_prefix != "" ? var.name_prefix : var.resource_group_name
}

resource "ibm_resource_instance" "create_postgresql_instance" {
  count = var.server_exists != "true" ? 1 : 0

  name              = "${replace(local.name_prefix, "/[^a-zA-Z0-9_\\-\\.]/", "")}-postgresql"
  service           = "databases-for-postgresql"
  plan              = var.plan
  location          = var.resource_location
  resource_group_id = data.ibm_resource_group.tools_resource_group.id
  tags              = var.tags

  timeouts {
    create = "30m"
    update = "30m"
    delete = "30m"
  }
}

data "ibm_resource_instance" "postgresql_instance" {
  depends_on        = [ibm_resource_instance.create_postgresql_instance]

  name              = "${replace(local.name_prefix, "/[^a-zA-Z0-9_\\-\\.]/", "")}-postgresql"
  service           = "databases-for-postgresql"
  location          = var.resource_location
  resource_group_id = data.ibm_resource_group.tools_resource_group.id
}

resource "ibm_resource_key" "postgresql_credentials" {
  count = var.server_exists != "true" ? 1 : 0

  name                 = "${data.ibm_resource_instance.postgresql_instance.name}-key"
  role                 = local.role
  resource_instance_id = data.ibm_resource_instance.postgresql_instance.id
}

data "ibm_resource_key" "postgresql" {
  depends_on            = [ibm_resource_key.postgresql_credentials]

  name                  = "${data.ibm_resource_instance.postgresql_instance.name}-key"
  resource_instance_id  = data.ibm_resource_instance.postgresql_instance.id
}

locals {
  jsoncredentials  = yamlencode(data.ibm_resource_key.postgresql.credentials)
  credentials      = yamldecode(local.jsoncredentials)
  username         = local.credentials["connection.postgres.authentication.username"]
  password         = local.credentials["connection.postgres.authentication.password"]
  hostname         = local.credentials["connection.postgres.hosts.0.hostname"]
  port             = local.credentials["connection.postgres.hosts.0.port"]
  dbname           = local.credentials["connection.postgres.database"]
}

resource "ibm_container_bind_service" "postgresql_service_binding" {
  count      = var.namespace_count

  cluster_name_id       = var.cluster_id
  service_instance_name = data.ibm_resource_instance.postgresql_instance.name
  namespace_id          = var.namespaces[count.index]
  resource_group_id     = data.ibm_resource_group.tools_resource_group.id
  key                   = data.ibm_resource_key.postgresql.name

  // The provider (v16.1) is incorrectly registering that these values change each time,
  // this may be removed in the future if this is fixed.
  lifecycle {
    ignore_changes = [id, namespace_id, service_instance_name]
  }
}