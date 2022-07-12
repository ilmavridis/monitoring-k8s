output "grafana_service_node_port" {
  value       = kubernetes_service.grafana.spec[0].port[0].node_port
  description = "Grafana service node port"
}