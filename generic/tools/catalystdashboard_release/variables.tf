variable "cluster_config_file" {
  type        = "string"
  description = "Cluster config file for Kubernetes cluster."
}

variable "releases_namespace" {
  type        = "string"
  description = "Name of the existing namespace where the Helm Releases will be deployed."
}

variable "cluster_ingress_hostname" {
  type        = "string"
  description = "Ingress hostname of the IKS cluster."
}

variable "cluster_type" {
  description = "The cluster type (openshift or kubernetes)"
}

variable "tool_config_maps" {
  type = "list"
  description = "The list of config maps containing connectivity information for tools"
  default = []
}

variable "tls_secret_name" {
  description = "The name of the secret containing the tls certificate values"
  default     = ""
}

variable "image_tag" {
  description = "The image version tag to use"
  default     = "1.0.14"
}
