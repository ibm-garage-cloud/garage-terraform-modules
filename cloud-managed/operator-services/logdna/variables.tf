variable "resource_group_name" {
  type        = string
  description = "Existing resource group where the IKS cluster will be provisioned."
}

variable "resource_location" {
  type        = string
  description = "Geographic location of the resource (e.g. us-south, us-east)"
}

variable "cluster_config_file_path" {
  type        = string
  description = "The path to the config file for the cluster"
}

variable "cluster_type" {
  type        = string
  description = "The type of cluster that should be created (openshift or ocp3 or ocp4 or kubernetes)"
}

variable "service_account_name" {
  type        = string
  description = "The service account that the logdna agent should run under"
  default     = "default"
}

variable "name_prefix" {
  type        = string
  description = "The prefix name for the service. If not provided it will default to the resource group name"
  default     = ""
}

variable "plan" {
  type        = string
  description = "The type of plan the service instance should run under (lite, 7-day, 14-day, or 30-day)"
  default     = "7-day"
}

variable "namespace" {
  type        = string
  description = "The namespace where the agent should be deployed"
  default     = "tools"
}

variable "service_namespace" {
  type        = string
  description = "The namespace where the service obj will be created"
}

variable "bind_script_version" {
  type        = string
  description = "The version of the bind script that will be applied - https://github.com/logdna/logdna-agent/releases"
  default     = "1.6.2"
}

variable "tags" {
  type        = list(string)
  description = "Tags that should be applied to the service"
  default     = []
}
