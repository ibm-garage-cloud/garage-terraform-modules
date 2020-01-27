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

variable "namespace_count" {
  type        = number
  description = "The number of namespaces"
}

variable "namespaces" {
  type        = list(string)
  description = "Namespaces"
}

variable "tags" {
  type        = list(string)
  description = "Tags that should be applied to the service"
  default     = []
}

variable "name_prefix" {
  type        = string
  description = "The prefix name for the service. If not provided it will default to the resource group name"
  default     = ""
}

variable "plan" {
  type        = string
  description = "The type of plan the service instance should run under (standard)"
  default     = "standard"
}
