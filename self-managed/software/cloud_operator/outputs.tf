output "namespace" {
  value       = "ibmcloud-operators"
  description = "namespace where the operator is running"
  depends_on  = [null_resource.deploy_cloud_operator]
}
