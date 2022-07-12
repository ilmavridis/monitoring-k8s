variable "monitoring_namespace" {
  type        = string
  description = "Kubernetes namespace for Prometheus - Grafana"
}

variable "grafana_port" {
  type        = number
  description = "Grafana Service node port"
}

variable "grafana_within_cluster_port"{
  type        = number
  description = "Grafana service within cluster port"
}

variable "prometheus_within_cluster_port"{
  type        = number
  description = "Prometheus service within cluster port"
}
