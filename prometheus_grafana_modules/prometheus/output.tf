output "prometheus_service_node_port" {
  value       = kubernetes_service.prometheus.spec[0].port[0].node_port
  description = "Prometheus service node port"
}

output "prometheus_in_cluster_port" {
  value = "${kubernetes_service.prometheus.spec[0].port[0].port}"
}

output "alertmanager_within_cluster_port" {
  value = "${var.alertmanager_within_cluster_port}"
}