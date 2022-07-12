variable "monitoring_namespace" {
  type        = string
  description = "Kubernetes namespace for Prometheus - Grafana"
}

variable "prometheus_port" {
  type        = number
  description = "Prometheus service node port"
}

variable "prometheus_within_cluster_port"{
  type        = number
  description = "Prometheus service within cluster port"
}

variable "metrics_within_cluster_port"{
  type        = number
  description = "Metrics service within cluster port"
}


variable "alertmanager_within_cluster_port"{
  type        = number
  description = "Alertmanager service within cluster port"
}