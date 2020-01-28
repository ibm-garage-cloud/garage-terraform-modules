provider "ibm" {
}
provider "null" {
}
provider "local" {
}

data "ibm_resource_group" "resource_group" {
  name = var.resource_group_name
}

resource "null_resource" "ibmcloud_login" {
  provisioner "local-exec" {
    command = "ibmcloud login -r $${REGION} -g $${RESOURCE_GROUP} --apikey $${APIKEY} > /dev/null"

    environment = {
      REGION         = var.cluster_region
      RESOURCE_GROUP = var.resource_group_name
      APIKEY         = var.ibmcloud_api_key
    }
  }
}

locals {
  server_url_file       = "${path.cwd}/.tmp/server-url.val"
  cluster_type_file     = "${path.cwd}/.tmp/cluster_type.val"
  cluster_version_file  = "${path.cwd}/.tmp/cluster_version.val"
  ingress_url_file      = "${path.cwd}/.tmp/ingress-subdomain.val"
  kube_version_file     = "${path.cwd}/.tmp/kube_version.val"
  tls_secret_file       = "${path.cwd}/.tmp/tls_secret.val"
  registry_url_file     = "${path.cwd}/.tmp/registry_url.val"
  cluster_config_dir    = "${var.kubeconfig_download_dir}/.kube"
  name_prefix           = var.name_prefix != "" ? var.name_prefix : var.resource_group_name
  name_list             = [local.name_prefix, "cluster"]
  cluster_name          = var.cluster_name != "" ? var.cluster_name : join("-", local.name_list)
  tmp_dir               = "${path.cwd}/.tmp"
  config_namespace      = "default"
  ibmcloud_apikey_chart = "${path.module}/charts/ibmcloud"
  config_file_path      = var.cluster_type == "kubernetes" ? data.ibm_container_cluster_config.cluster.config_file_path : ""
  cluster_type_tag      = var.cluster_type == "kubernetes" ? "iks" : "ocp"
}

resource "null_resource" "get_openshift_version" {
  depends_on = [null_resource.ibmcloud_login]
  count = var.cluster_type == "openshift" || var.cluster_type == "ocp3" ? 1 : 0

  provisioner "local-exec" {
    command = "ibmcloud ks versions --show-version openshift | grep default | sed -E \"s/^(.*) [(]default[)].*/\\1/g\" | xargs echo -n > ${local.kube_version_file}"
  }
}

resource "null_resource" "get_openshift4_version" {
  depends_on = [null_resource.ibmcloud_login]
  count = var.cluster_type == "ocp4" ? 1 : 0

  provisioner "local-exec" {
    command = "ibmcloud ks versions --show-version openshift | grep -E \"^4.*\" | xargs echo -n > ${local.kube_version_file}"
  }
}

resource "null_resource" "get_kubernetes_version" {
  depends_on = [null_resource.ibmcloud_login]
  count = var.cluster_type == "kubernetes" ? 1 : 0

  provisioner "local-exec" {
    command = "ibmcloud ks versions --show-version kubernetes | grep default | sed -E \"s/^(.*) [(]default[)].*/\\1/g\" | xargs echo -n > ${local.kube_version_file}"
  }
}

data "local_file" "latest_kube_version" {
  depends_on = [
    null_resource.get_openshift_version,
    null_resource.get_openshift4_version,
    null_resource.get_kubernetes_version,
  ]

  filename = local.kube_version_file
}

resource "ibm_container_cluster" "create_cluster" {
  count             = var.cluster_exists == "true" ? 0 : 1

  name              = local.cluster_name
  datacenter        = var.vlan_datacenter
  kube_version      = data.local_file.latest_kube_version.content
  machine_type      = var.cluster_machine_type
  hardware          = var.cluster_hardware
  default_pool_size = var.cluster_worker_count
  resource_group_id = data.ibm_resource_group.resource_group.id
  private_vlan_id   = var.private_vlan_id
  public_vlan_id    = var.public_vlan_id
  tags              = [local.cluster_type_tag]
}

resource "null_resource" "create_cluster_config_dir" {
  provisioner "local-exec" {
    command = "mkdir -p ${local.cluster_config_dir}"
  }
}

data "ibm_container_cluster_config" "cluster" {
  depends_on        = [
    ibm_container_cluster.create_cluster,
    null_resource.ibmcloud_login,
    null_resource.create_cluster_config_dir
  ]

  cluster_name_id   = local.cluster_name
  resource_group_id = data.ibm_resource_group.resource_group.id
  config_dir        = local.cluster_config_dir
}

resource "null_resource" "create_cluster_pull_secret_iks" {
  provisioner "local-exec" {
    command = "${path.module}/scripts/cluster-pull-secret-apply.sh ${local.cluster_name}"

    environment = {
      KUBECONFIG_IKS = local.config_file_path
    }
  }
}

resource "null_resource" "get_server_url" {
  depends_on = [
    data.ibm_container_cluster_config.cluster,
    null_resource.ibmcloud_login,
  ]

  provisioner "local-exec" {
    command = "ibmcloud ks cluster get --cluster ${local.cluster_name} | grep \"Master URL\" | sed -E \"s/Master URL: +(.*)$/\\1/g\" | xargs echo -n > $${FILE}"

    environment = {
      FILE         = local.server_url_file
    }
  }
}

data "local_file" "server_url" {
  depends_on = [null_resource.get_server_url]

  filename = local.server_url_file
}

resource "null_resource" "get_tls_secret_name" {
  depends_on = [
    data.ibm_container_cluster_config.cluster,
    null_resource.ibmcloud_login,
  ]

  provisioner "local-exec" {
    command = "ibmcloud ks cluster get --cluster ${local.cluster_name} | grep \"Ingress Secret\" | sed -E \"s/Ingress Secret: +(.*)$/\\1/g\" | xargs echo -n > $${FILE}"

    environment = {
      FILE         = local.tls_secret_file
    }
  }
}

data "local_file" "tls_secret_name" {
  depends_on = [null_resource.get_tls_secret_name]

  filename = local.tls_secret_file
}

resource "null_resource" "get_ingress_subdomain" {
  depends_on = [
    data.ibm_container_cluster_config.cluster,
    null_resource.ibmcloud_login,
  ]

  provisioner "local-exec" {
    command = "ibmcloud ks cluster get --cluster $${CLUSTER_NAME} | grep \"Ingress Subdomain\" | sed -E \"s/Ingress Subdomain: +(.*)$/\\1/g\" | xargs echo -n > $${FILE}"

    environment = {
      CLUSTER_NAME = local.cluster_name
      FILE         = local.ingress_url_file
    }
  }
}

data "local_file" "ingress_subdomain" {
  depends_on = [null_resource.get_ingress_subdomain]

  filename = local.ingress_url_file
}

resource "null_resource" "get_cluster_type" {
  depends_on = [
    data.ibm_container_cluster_config.cluster,
    null_resource.ibmcloud_login,
  ]

  provisioner "local-exec" {
    command = "if [[ -n $(ibmcloud ks cluster get --cluster $${CLUSTER_NAME} | grep -E \"Version.*openshift\") ]]; then echo -n \"openshift\" > $${FILE}; else echo -n \"kubernetes\" > $${FILE}; fi"

    environment = {
      CLUSTER_NAME = local.cluster_name
      FILE         = local.cluster_type_file
    }
  }
}

data "local_file" "cluster_type" {
  depends_on = [null_resource.get_cluster_type]

  filename = local.cluster_type_file
}

resource "null_resource" "get_cluster_version" {
  depends_on = [
    data.ibm_container_cluster_config.cluster,
    null_resource.ibmcloud_login,
  ]

  provisioner "local-exec" {
    command = "ibmcloud ks cluster get --cluster $${CLUSTER_NAME} | grep \"Version\" | sed -E \"s/Version: +(.*)$/\\1/g ; s/^([0-9]+\\.[0-9]+).*/\\1/g\" | xargs echo -n > $${FILE}"

    environment = {
      CLUSTER_NAME = local.cluster_name
      FILE         = local.cluster_version_file
    }
  }
}

data "local_file" "cluster_version" {
  depends_on = [null_resource.get_cluster_version]

  filename = local.cluster_version_file
}

resource "null_resource" "check_cluster_type" {
  provisioner "local-exec" {
    command = "if [[ \"$${PROVIDED_CLUSTER_TYPE}\" != \"$${ACTUAL_CLUSTER_TYPE}\" ]]; then echo \"Provided cluster type does not match the value from the server: $${ACTUAL_CLUSTER_TYPE}\"; exit 1; fi"

    environment = {
      PROVIDED_CLUSTER_TYPE = replace(var.cluster_type, "/ocp[34]/", "openshift")
      ACTUAL_CLUSTER_TYPE   = data.local_file.cluster_type.content
    }
  }
}

resource "null_resource" "oc_login" {
  count      = var.cluster_type != "kubernetes" ? 1: 0

  provisioner "local-exec" {
    command = "oc login -u ${var.login_user} -p ${var.ibmcloud_api_key} --server=${data.local_file.server_url.content} > /dev/null"
  }
}

resource "null_resource" "create_registry_namespace" {
  provisioner "local-exec" {
    command = "${path.module}/scripts/create-registry-namespace.sh ${var.resource_group_name} ${var.cluster_region} ${local.registry_url_file}"

    environment = {
      APIKEY = var.ibmcloud_api_key
    }
  }
}

data "local_file" "registry_url" {
  depends_on = [null_resource.create_registry_namespace]

  filename = local.registry_url_file
}

resource "null_resource" "ibmcloud_apikey_release" {
  depends_on = [null_resource.oc_login]

  provisioner "local-exec" {
    command = "${path.module}/scripts/deploy-ibmcloud-config.sh ${local.ibmcloud_apikey_chart} ${local.config_namespace} ${var.ibmcloud_api_key} ${var.resource_group_name} ${data.local_file.server_url.content} ${var.cluster_type} ${local.cluster_name} ${data.local_file.ingress_subdomain.content} ${var.cluster_region} ${data.local_file.registry_url.content} ${data.local_file.tls_secret_name.content} ${data.local_file.cluster_version.content}"

    environment = {
      KUBECONFIG_IKS = local.config_file_path
      TMP_DIR        = local.tmp_dir
    }
  }
}
