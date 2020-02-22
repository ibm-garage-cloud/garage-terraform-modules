output "postgresql_service_account_username" {
  value       = local.username
  description = "Username for the Databases for PostgreSQL service account."
}

output "postgresql_service_account_password" {
  value       = local.password
  description = "Password for the Databases for PostgreSQL Sservice account."
  sensitive   = true
}

output "postgresql_hostname" {
  value       = local.hostname
  description = "Hostname for the Databases for PostgreSQL instance."
}

output "postgresql_port" {
  value       = local.port
  description = "Port for the Databases for PostgreSQL instance."
}

output "postgresql_database_name" {
  value       = local.dbname
  description = "Database name for the Databases for PostgreSQL instance."
}
