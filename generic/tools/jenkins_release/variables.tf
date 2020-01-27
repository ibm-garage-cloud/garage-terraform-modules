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
  description = "Ingress hostname of the IKS cluster."
}

variable "cluster_type" {
  type        = string
  description = "The cluster type (openshift or ocp3 or ocp4 or kubernetes)"
}

variable "tls_secret_name" {
  type        = string
  description = "The secret containing the tls certificates"
  default = ""
}

variable "volume_capacity" {
  type        = string
  description = "The volume capacity of the persistence volume claim"
  default     = "2Gi"
}

variable "storage_class" {
  type        = string
  description = "The storage class of the persistence volume claim"
  default     = "ibmc-file-gold"
}

variable "helm_version" {
  type        = string
  description = "The version of helm chart that should be deployed"
  default     = "1.7.9"
}

variable "server_url" {
  type        = string
  description = "The public url of the openshift/kubernetes cluster"
  default     = ""
}
