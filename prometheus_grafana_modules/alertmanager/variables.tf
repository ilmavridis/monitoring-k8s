variable "monitoring_namespace" {
  type        = string
  description = "Kubernetes namespace for Prometheus - Grafana"
}

variable "alertmanager_port" {
  type        = number
  description = "Alertmanager Service node port"
}

variable "alertmanager_within_cluster_port"{
  type        = number
  description = "Alertmanager service within cluster port"
}

variable "alertmanager_fromemail" {
  type        = string
  description = "Alertmanager from email"
  sensitive   = true
}

variable "alertmanager_toemail" {
  type        = string
  description = "Alertmanager to email"
  sensitive   = true
}

variable "alertmanager_password" {
  type        = string
  description = "Alertmanager email password"
  sensitive   = true
}

variable "alertmanager_host" {
  type        = string
  description = "Alertmanager mail host"
  sensitive   = true
}