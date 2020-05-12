provider "helm" {
  version = ">= 1.1.1"

  kubernetes {
    config_path = var.cluster_config_file
  }
}

locals {
  tmp_dir      = "${path.cwd}/.tmp"
  cluster_type = var.cluster_type == "kubernetes" ? "kubernetes" : "openshift"
  ingress_host = "dashboard-${var.releases_namespace}.${var.cluster_ingress_hostname}"
  endpoint_url = "http${var.tls_secret_name != "" ? "s" : ""}://${local.ingress_host}"
}

data "helm_repository" "toolkit-charts" {
  name = "toolkit-charts"
  url  = "https://ibm-garage-cloud.github.io/toolkit-charts/"
}

resource "helm_release" "developer-dashboard" {
  name         = "developer-dashboard"
  repository   = data.helm_repository.toolkit-charts.name
  chart        = "developer-dashboard"
  version      = var.chart_version
  namespace    = var.releases_namespace
  force_update = true

  set {
    name  = "clusterType"
    value = local.cluster_type
  }

  set {
    name  = "ingressSubdomain"
    value = var.cluster_ingress_hostname
  }

  set {
    name  = "sso.enabled"
    value = var.enable_sso
  }

  set {
    name  = "tlsSecretName"
    value = var.tls_secret_name
  }
}


resource "helm_release" "dashboard-config" {
  depends_on = [helm_release.developer-dashboard]

  name         = "dashboard"
  repository   = data.helm_repository.toolkit-charts.name
  chart        = "tool-config"
  namespace    = var.releases_namespace
  force_update = true

  set {
    name  = "url"
    value = local.endpoint_url
  }
}
