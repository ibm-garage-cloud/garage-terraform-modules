variable "cluster_config_file_path" {
  type        = string
  description = "The path to the config file for the cluster"
}

variable "tools_namespace" {
  type        = string
  description = "The namespaces to create"
}

variable "other_namespaces" {
  type        = list(string)
  description = "The namespaces to create"
}

variable "cluster_type" {
  type        = string
  description = "The type of cluster that should be created (openshift or ocp3 or ocp4 or kubernetes)"
}

variable "tls_secret_name" {
  type        = string
  description = "The name of the secret containing the tls certificate for the cluster"
  default     = ""
}
