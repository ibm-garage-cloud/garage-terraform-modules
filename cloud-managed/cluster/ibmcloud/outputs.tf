output "id" {
  value       = data.ibm_container_cluster_config.cluster.id
  description = "ID of the cluster."
  depends_on  = [helm_release.ibmcloud_config]
}

output "name" {
  value       = local.cluster_name
  description = "Name of the cluster."
}

output "resource_group_name" {
  value       = var.resource_group_name
  description = "Name of the resource group containing the cluster."
}

output "region" {
  value       = var.cluster_region
  description = "Region containing the cluster."
}

output "ingress_hostname" {
  value       = local.ingress_hostname
  description = "Ingress hostname of the cluster."
}

output "server_url" {
  value       = local.server_url
  description = "The url of the control server."
}

output "config_file_path" {
  value       = local.config_file_path
  description = "Path to the config file for the cluster."
  depends_on  = [helm_release.ibmcloud_config]
}

output "type" {
  value       = local.cluster_type
  description = "The type of cluster (openshift or ocp4 or ocp3 or kubernetes)"
  depends_on  = [helm_release.ibmcloud_config]
}

output "version" {
  value       = data.local_file.cluster_version.content
  description = "The point release version number of cluster (3.11 or 4.3 or 1.16)"
  depends_on  = [helm_release.ibmcloud_config]
}

output "login_user" {
  value       = var.login_user
  description = "The username used to log into the openshift cli"
}

output "login_password" {
  depends_on  = [null_resource.oc_login]
  value       = var.ibmcloud_api_key
  description = "The password used to log into the openshift cli"
}

output "ibmcloud_api_key" {
  depends_on  = [null_resource.oc_login]
  value       = var.ibmcloud_api_key
  description = "The API key for the environment"
}

output "tls_secret_name" {
  value       = local.tls_secret
  description = "The name of the secret containin the tls information for the cluster"
}

output "tag" {
  value       = local.cluster_type_tag
  description = "The tag vased on the cluster type"
}
