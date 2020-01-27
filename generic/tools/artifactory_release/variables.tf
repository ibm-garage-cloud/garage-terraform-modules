variable "cluster_config_file" {
  type        = string
  description = "Cluster config file for Kubernetes cluster."
}

variable "releases_namespace" {
  type        = string
  description = "Name of the existing namespace where Pact Broker will be deployed."
}

variable "cluster_ingress_hostname" {
  type        = string
  description = "Ingress hostname of the cluster."
}

variable "cluster_type" {
  type        = string
  description = "The cluster type (openshift or ocp3 or ocp4 or kubernetes)"
}

variable "service_account" {
  type        = string
  description = "The service account under which the artifactory pods should run"
}

variable "tls_secret_name" {
  type        = string
  description = "The name of the secret containing the tls certificate values"
  default     = ""
}

variable "chart_version" {
  type        = string
  description = "The chart version that will be used for artifactory release"
  default     = "7.18.1"
}

variable "storage_class" {
  type        = string
  description = "The storage class of the persistence volume claim"
  default     = "ibmc-file-gold"
}
