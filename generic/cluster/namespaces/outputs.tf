output "tools_namespace_name" {
  value       = var.tools_namespace
  description = "Namespace where development tools will be deployed"
  depends_on  = [
    null_resource.create_pull_secrets,
    null_resource.copy_cloud_configmap,
    null_resource.copy_apikey_secret
  ]
}

output "release_namespaces" {
  value       = var.release_namespaces
  description = "Namespaces where applications will be deployed"
  depends_on  = [
    null_resource.create_pull_secrets,
    null_resource.copy_cloud_configmap,
    null_resource.copy_apikey_secret
  ]
}
