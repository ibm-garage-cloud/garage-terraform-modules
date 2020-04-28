output "ingress_host" {
  description = "The ingress host for the Catalyst Dashboard instance"
  value       = "dashboard-${var.releases_namespace}.${var.cluster_ingress_hostname}"
}
