output "ingress_host" {
  description = "The ingress host for the Catalyst Dashboard instance"
  value       = local.ingress_host
  depends_on = [helm_release.developer-dashboard]
}
