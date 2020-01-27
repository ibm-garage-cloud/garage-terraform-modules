output "ingress_host" {
  description = "The ingress host for the Argo CD instance"
  value       = local.ingress_host
  depends_on  = [null_resource.argocd_release]
}

output "ingress_url" {
  description = "The ingress url for the Argo CD instance"
  value       = local.ingress_url
  depends_on  = [null_resource.argocd_release]
}

output "config_name" {
  description = "The name of the secret created to store the url"
  value       = local.config_name
  depends_on  = [null_resource.argocd_release]
}

output "secret_name" {
  description = "The name of the secret created to store the credentials"
  value       = local.secret_name
  depends_on  = [null_resource.argocd_release]
}
