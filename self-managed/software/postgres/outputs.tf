output "postgresql_service_account_username" {
  value       = var.postgresql_user
  description = "Username for the Databases for PostgreSQL service account."
}

output "postgresql_service_account_password" {
  value       = var.postgresql_password
  description = "Password for the Databases for PostgreSQL Sservice account."
  sensitive   = true
}

output "postgresql_hostname" {
  value     = "postgresql"
  description = "Hostname for the Databases for PostgreSQL instance."
  depends_on  = [null_resource.postgresql_release]
}

output "postgresql_port" {
  value       = "5432"
  description = "Port for the Databases for PostgreSQL instance."
  depends_on  = [null_resource.postgresql_release]
}

output "postgresql_database_name" {
  value       = var.postgresql_database
  description = "Database name for the Databases for PostgreSQL instance."
}
