output "id" {
  value       = "123"
  description = "ID of the cluster."
}

output "name" {
  value       = var.cluster_name
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
  value       = var.ingress_subdomain
  description = "Ingress hostname of the cluster."
  depends_on = [null_resource.oc_login]
}

output "server_url" {
  value       = var.server_url
  description = "The url of the control server."
  depends_on = [null_resource.oc_login]
}

output "config_file_path" {
  value       = local.config_file_path
  description = "Path to the config file for the cluster."
  depends_on  = [null_resource.ibmcloud_apikey_release]
}

output "type" {
  value       = "openshift"
  description = "The type of cluster (openshift or ocp3 or ocp4 or kubernetes)"
  depends_on  = [null_resource.ibmcloud_apikey_release]
}

output "login_user" {
  value       = var.login_user
  description = "The username used to log into the openshift cli"
}

output "login_password" {
  value       = var.ibmcloud_api_key
  description = "The password used to log into the openshift cli"
}

output "ibmcloud_api_key" {
  value       = var.ibmcloud_api_key
  depends_on  = [null_resource.ibmcloud_apikey_release]
  description = "The API key for the environment"
}

output "tls_secret_name" {
  value       = var.tls_secret_name
  description = "The name of the secret containing the tls information for the cluster"
}
