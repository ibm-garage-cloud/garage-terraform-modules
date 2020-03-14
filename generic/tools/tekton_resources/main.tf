provider "null" {
}

locals {
  tmp_dir = "${path.cwd}/.tmp"
}

resource "null_resource" "tekton_resources" {

  triggers = {
    kubeconfig         = var.cluster_config_file_path
    tools_namespace    = var.resource_namespace
  }

  provisioner "local-exec" {
    command = "${path.module}/scripts/deploy-tekton-resources.sh ${self.triggers.tools_namespace} ${var.pre_tekton} ${var.revision} ${var.git_url}"

    environment = {
      KUBECONFIG       = self.triggers.kubeconfig
      TMP_DIR          = "${local.tmp_dir}"
    }
  }

  provisioner "local-exec" {
    when    = destroy
    command = "${path.module}/scripts/destroy-tekton-resources.sh ${self.triggers.tools_namespace}"

    environment = {
      KUBECONFIG = self.triggers.kubeconfig
    }
  }
}
