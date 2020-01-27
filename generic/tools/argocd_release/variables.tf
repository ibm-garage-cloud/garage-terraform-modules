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
  description = "The name of the secret containing the tls certificate values"
  default     = ""
}

variable "helm_version" {
  type        = string
  description = "The version of helm chart that should be deployed"
  default     = "1.0.0"
}

# If enable_cache is not set to true, then Argo will not be able to synchronize
# deployed resources or display the YAML it generated for them.
# See upstream bug: https://github.com/argoproj/argo-helm/issues/157
variable "enable_cache" {
  type        = string
  description = "Enable redis caching layer in Argo CD deployment"
  default     = "true"
}
