## Global
variable "monitoring_namespace" {
  type        = string
  description = "Kubernetes namespace for Prometheus - Grafana"
  default     = "monitoring"
}

## Prometheus
variable "prometheus_port" {
  type        = number
  description = "Prometheus service node port"
  default     = 30100
}

variable "prometheus_within_cluster_port"{
  type        = number
  description = "Prometheus service within cluster port"
  default     = 9090
}

variable "metrics_within_cluster_port"{
  type        = number
  description = "Metrics service within cluster port"
  default     = 9091
}

variable "alertmanager_within_cluster_port"{
  type        = number
  description = "Alertmanager service within cluster port"
  default = 9093
}

## Grafana
variable "grafana_port" {
  type        = number
  description = "Grafana service node port"
  default     = 30200
}

variable "grafana_within_cluster_port"{
  type        = number
  description = "Grafana service within cluster port"
  default     = 9092
}


## Alertmanager
variable "alertmanager_port" {
  type        = number
  description = "Alertmanager service node port"
  default     = 30300
}

variable "alertmanager_fromemail" {
  type        = string
  description = "Alertmanager from email"
  default     = "sender@mail.com"
  sensitive   = true
}

variable "alertmanager_toemail" {
  type        = string
  description = "Alertmanager to email"
  default     = "receiver@mail.com"
  sensitive   = true
}

variable "alertmanager_password" {
  type        = string
  description = "Alertmanager email password"
  default     = "p@$$w0rD"
  sensitive   = true
}

variable "alertmanager_host" {
  type        = string
  description = "Alertmanager mail host"
  default     = "ssmtp.mmmail.com:587"
  sensitive   = true
}

