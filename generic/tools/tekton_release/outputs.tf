output "namespace" {
  description = "The namespace where Tekton was deployed"
  value       = local.namespace
  depends_on  = [null_resource.copy_cloud_configmap]
}

