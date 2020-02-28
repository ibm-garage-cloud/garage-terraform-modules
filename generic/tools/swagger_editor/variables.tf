variable "cluster_config_file" {
  type        = string
  description = "Cluster config file for Kubernetes cluster."
}

variable "releases_namespace" {
  type        = string
  description = "Name of the existing namespace where the Helm Releases will be deployed."
}

variable "cluster_ingress_hostname" {
  type        = string
  description = "Ingress hostname of the cluster."
}

variable "cluster_type" {
  description = "The cluster type (openshift or kubernetes)"
}

variable "tls_secret_name" {
  description = "The name of the secret containing the tls certificate values"
  default     = ""
}

variable "image_tag" {
  description = "The image version tag to use"
  default     = "v3.8.0"
}

variable "enable_oauth" {
  description = "Flag indicating if oauth should be applied (only available for OpenShift)"
  default     = "true"
}
