variable "resource_group_name" {
  type        = string
  description = "Resource group where the cluster has been provisioned."
}

variable "resource_location" {
  type        = string
  description = "Geographic location of the resource (e.g. us-south, us-east)"
  default     = "global"
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
  description = "The type of plan the service instance should run under (lite or standard)"
  default     = "standard"
}
