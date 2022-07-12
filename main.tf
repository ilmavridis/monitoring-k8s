terraform {
  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = ">= 2.0.0"
    }
  }
}


provider "kubernetes" {
  config_path = "~/.kube/config"
}


resource "kubernetes_namespace" "monitoring" {
  metadata {
    name = var.monitoring_namespace
  }
}


module "prometheus" {
        source = "./prometheus_grafana_modules/prometheus"
        monitoring_namespace = kubernetes_namespace.monitoring.metadata[0].name
        prometheus_port = 30100
        prometheus_within_cluster_port = 9090
        metrics_within_cluster_port = 9091
        alertmanager_within_cluster_port = 9093
}  


module "grafana" {
        source = "./prometheus_grafana_modules/grafana"
        depends_on = [module.prometheus]
        monitoring_namespace = kubernetes_namespace.monitoring.metadata[0].name
        grafana_port = 30200
        grafana_within_cluster_port = 9092
        prometheus_within_cluster_port = "${module.prometheus.prometheus_in_cluster_port}"
}


module "alertmanager" {
        source = "./prometheus_grafana_modules/alertmanager"
        depends_on = [module.prometheus]
        monitoring_namespace = kubernetes_namespace.monitoring.metadata[0].name
        alertmanager_port = 30300
        alertmanager_within_cluster_port = "${module.prometheus.alertmanager_within_cluster_port}"
        alertmanager_fromemail = "sender@mail.com"
        alertmanager_toemail = "receiver@mail.com"
        alertmanager_password = "p@$$w0rD"
        alertmanager_host = "ssmtp.mmmail.com:587"
}