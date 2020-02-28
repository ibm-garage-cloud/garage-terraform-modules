provider "null" {
}

locals {
  tmp_dir = "${path.cwd}/.tmp"
}

resource "null_resource" "tekton_resources" {
  provisioner "local-exec" {
    command = "${path.module}/scripts/deploy-tekton-resources.sh ${var.resource_namespace} ${var.pre_tekton}"

    environment = {
      KUBECONFIG   = "${var.cluster_config_file_path}"
      TMP_DIR          = "${local.tmp_dir}"
      TEKTON_NAMESPACE = "${var.tekton_namespace}"
    }
  }
}
