variable "resource_group_name" {
  type        = "string"
  description = "Existing resource group where the IKS cluster will be provisioned."
}

variable "resource_location" {
  type        = "string"
  description = "Geographic location of the resource (e.g. us-south, us-east)"
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

variable "cluster_config_file_path" {
  type        = "string"
  description = "The path to the config file for the cluster"
}

variable "cluster_type" {
  type        = "string"
  description = "The type of cluster that should be created (openshift or kubernetes)"
}

variable "name_prefix" {
  type        = "string"
  description = "The prefix name for the service. If not provided it will default to the resource group name"
  default     = ""
}

variable "plan" {
  type        = "string"
  description = "The type of plan the service instance should run under (trial or graduated-tier)"
  default     = "graduated-tier"
}
