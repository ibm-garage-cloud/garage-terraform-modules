output "tools_namespace_name" {
  value       = kubernetes_namespace.tools.metadata.name
  description = "Namespace where development tools will be deployed"
  depends_on  = [kubernetes_namespace.tools]
}

output "release_namespaces" {
  value       = var.release_namespaces
  description = "Namespaces where applications will be deployed"
  depends_on  = [null_resource.create_release_namespaces]
}
