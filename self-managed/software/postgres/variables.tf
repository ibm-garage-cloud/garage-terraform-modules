variable "resource_group_name" {
  type        = string
  description = "Existing resource group where the IKS cluster will be provisioned."
}

variable "resource_location" {
  type        = string
  description = "Location for resources to be provisioned (e.g. \"us-east\")."
}

variable "server_exists" {
  type        = string
  description = "Flag indicating whether a database server already exists (true or false)"
}

variable "cluster_id" {
  type        = string
  description = "Id of the cluster"
}

variable "tools_namespace" {
  type        = string
  description = "Tools namespace"
}

variable "dev_namespace" {
  type        = string
  description = "Development namespace"
}

variable "test_namespace" {
  type        = string
  description = "Test namespace"
}

variable "staging_namespace" {
  type        = string
  description = "Staging namespace"
}

variable "cluster_type" {
  type        = string
  description = "String specifying cluster type"
}

variable "postgresql_user" {
  type        = string
  default     = "postgres"
  description = "String specifying the postgresql user"
}

variable "postgresql_password" {
  type        = string
  default     = "postgres"
  description = "String specifying the postgresql password"
}

variable "postgresql_database" {
  type        = string
  default     = "postgres"
  description = "String specifying the postgresql database"
}

variable "volume_capacity" {
  type        = string
  default     = "5Gi"
  description = "String specifying the volume capacity"
}
