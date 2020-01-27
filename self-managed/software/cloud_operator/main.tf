resource "null_resource" "deploy_cloud_operator" {
  provisioner "local-exec" {
    command = "${path.module}/scripts/deploy-cloud-operator.sh ${var.resource_group_name} ${var.resource_location}"

    environment={
      KUBECONFIG_IKS = "${var.cluster_config_file}"
      APIKEY         = "${var.ibmcloud_api_key}"
    }
  }
}
