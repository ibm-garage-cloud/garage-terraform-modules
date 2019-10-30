variable "resource_group_name" {
  type        = "string"
  description = "Resource group where the cluster has been provisioned."
}

variable "resource_location" {
  type        = "string"
  description = "Geographic location of the resource (e.g. us-south, us-east)"
}

variable "cluster_id" {
  type        = "string"
  description = "Id of the cluster"
}

variable "dev_namespace" {
  type        = "string"
  description = "Development namespace"
}

variable "test_namespace" {
  type        = "string"
  description = "Test namespace"
}

variable "staging_namespace" {
  type        = "string"
  description = "Staging namespace"
}

variable "name_prefix" {
  type        = "string"
  description = "The prefix name for the service. If not provided it will default to the resource group name"
  default     = ""
}

variable "plan" {
  type        = "string"
  description = "The type of plan the service instance should run under (lite or graduated-tier)"
  default     = "graduated-tier"
}
