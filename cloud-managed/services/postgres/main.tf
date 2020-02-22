provider "ibm" {
  version="1.2.1"
}

provider "local" {
}

provider "null" {
}

data "ibm_resource_group" "tools_resource_group" {
  name = var.resource_group_name
}

locals {
  tmp_dir          = "${path.cwd}/.tmp"
  credentials_file = "${path.cwd}/.tmp/postgres_credentials.json"
  hostname_file    = "${path.cwd}/.tmp/postgres_hostname.val"
  port_file        = "${path.cwd}/.tmp/postgres_port.val"
  username_file    = "${path.cwd}/.tmp/postgres_username.val"
  password_file    = "${path.cwd}/.tmp/postgres_password.val"
  dbname_file      = "${path.cwd}/.tmp/postgres_dbname.val"
  role             = "Administrator"
  name_prefix      = var.name_prefix != "" ? var.name_prefix : var.resource_group_name
  username         = data.local_file.username.content
  password         = data.local_file.password.content
  hostname         = data.local_file.hostname.content
  port             = data.local_file.port.content
  dbname           = data.local_file.dbname.content
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
  name                 = "${data.ibm_resource_instance.postgresql_instance.name}-key"
  role                 = local.role
  resource_instance_id = data.ibm_resource_instance.postgresql_instance.id
}

resource "ibm_container_bind_service" "postgresql_service_binding" {
  count      = var.namespace_count

  cluster_name_id       = var.cluster_id
  service_instance_name = data.ibm_resource_instance.postgresql_instance.name
  namespace_id          = var.namespaces[count.index]
  resource_group_id     = data.ibm_resource_group.tools_resource_group.id
  key                   = ibm_resource_key.postgresql_credentials.name

  // The provider (v16.1) is incorrectly registering that these values change each time,
  // this may be removed in the future if this is fixed.
  lifecycle {
    ignore_changes = [id, namespace_id, service_instance_name]
  }
}

resource "null_resource" "create_tmp" {
  provisioner "local-exec" {
    command = "mkdir -p ${local.tmp_dir}"
  }
}

// This is SUPER kludgy but it works... Need to revisit
resource "local_file" "write_postgres_credentials" {
  content    = jsonencode(ibm_resource_key.postgresql_credentials.credentials)
  filename   = local.credentials_file
  depends_on = [
    ibm_resource_key.postgresql_credentials,
    null_resource.create_tmp,
  ]
}

resource "null_resource" "write_hostname" {
  depends_on = [local_file.write_postgres_credentials]

  provisioner "local-exec" {
    command = "cat ${local.credentials_file} | sed -E \"s/.*host=([^ ]*).*/\\1/\" > ${local.hostname_file}"
  }
}

resource "null_resource" "write_port" {
  depends_on = [local_file.write_postgres_credentials]

  provisioner "local-exec" {
    command = "cat ${local.credentials_file} | sed -E \"s/.*port=([0-9]*).*/\\1/\" > ${local.port_file}"
  }
}

resource "null_resource" "write_username" {
  depends_on = [local_file.write_postgres_credentials]

  provisioner "local-exec" {
    command = "cat ${local.credentials_file} | sed -E \"s/.*user=([^ ]*).*/\\1/\" > ${local.username_file}"
  }
}

resource "null_resource" "write_password" {
  depends_on = [local_file.write_postgres_credentials]

  provisioner "local-exec" {
    command = "cat ${local.credentials_file} | sed -E \"s/.*PGPASSWORD=([^ ]*).*/\\1/\" > ${local.password_file}"
  }
}

resource "null_resource" "write_dbname" {
  depends_on = [local_file.write_postgres_credentials]

  provisioner "local-exec" {
    command = "cat ${local.credentials_file} | sed -E \"s/.*dbname=([^ ]*).*/\\1/\" > ${local.dbname_file}"
  }
}

data "local_file" "username" {
  depends_on = [null_resource.write_username]

  filename = local.username_file
}

data "local_file" "password" {
  depends_on = [null_resource.write_password]

  filename = local.password_file
}

data "local_file" "hostname" {
  depends_on = [null_resource.write_hostname]

  filename = local.hostname_file
}

data "local_file" "port" {
  depends_on = [null_resource.write_port]

  filename = local.port_file
}

data "local_file" "dbname" {
  depends_on = [null_resource.write_dbname]

  filename = local.dbname_file
}
