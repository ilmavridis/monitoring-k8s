output "prometheus_service_node_port" {
  value       = module.prometheus.prometheus_service_node_port
  description = "Prometheus service node port"
}

output "alertmanager_service_node_port" {
  value       = module.alertmanager.alertmanager_service_node_port
  description = "Alertmanager service node port"
}

output "grafana_service_node_port" {
  value       = module.grafana.grafana_service_node_port
  description = "Grafana service node port"
}