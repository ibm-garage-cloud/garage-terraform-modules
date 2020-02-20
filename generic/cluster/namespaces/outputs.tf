output "tools_namespace_name" {
  value       = var.tools_namespace
  description = "Tools namespace name"
  depends_on  = [null_resource.create_namespaces]
}

output "other_namespaces" {
  value       = var.other_namespaces
  description = "Other namespaces"
  depends_on  = [null_resource.create_namespaces]
}
