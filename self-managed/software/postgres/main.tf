locals {
  tmp_dir          = "${path.cwd}/.tmp"
  volume_capacity       = "5Gi"
}

resource "null_resource" "postgresql_release" {
  count = var.cluster_type != "kubernetes" ? 1 : 0

  triggers = {
    tools_namespace = var.namespaces[0]
  }
  
  provisioner "local-exec" {
    command = "${path.module}/scripts/deploy-postgres_openshift.sh"
    environment = {
      TMP_DIR             = local.tmp_dir
      POSTGRESQL_USER     = var.postgresql_user
      POSTGRESQL_PASSWORD = var.postgresql_password
      POSTGRESQL_DATABASE = var.postgresql_database
      VOLUME_CAPACITY     = var.volume_capacity
      NAMESPACE           = self.triggers.tools_namespace
    }
  }

  provisioner "local-exec" {
    when    = destroy
    command = "${path.module}/scripts/destroy-postgres.sh ${self.triggers.tools_namespace}"
  }
}
