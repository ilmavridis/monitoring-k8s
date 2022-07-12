output "alertmanager_service_node_port" {
  value       = kubernetes_service.alertmanager.spec[0].port[0].node_port
  description = "Alertmanager service node port"
}