resource "kubernetes_config_map" "grafana" {
  metadata {
    name      = "grafana-config"
    namespace = var.monitoring_namespace
  }
  data = {
    "grafana-config.yml" = <<eof
      {
          "apiVersion": 1,
          "datasources": [
              {
                "access":"proxy",
                  "editable": true,
                  "name": "prometheus",
                  "orgId": 1,
                  "type": "prometheus",
                  "url": "http://prometheus.monitoring.svc:${var.prometheus_within_cluster_port}",
                  "version": 1
              }
          ]
      }
    eof
  }
}


resource "kubernetes_deployment" "grafana" {
  metadata {
    name      = "grafana"
    namespace = var.monitoring_namespace
    labels = {
      app = "grafana"
    }
  }
  spec {
    selector {
      match_labels = {
        app = "grafana"
      }
    }
    template {
      metadata {
        labels = {
          app = "grafana"
        }
      }
      spec {
        container {
          name  = "grafana"
          image = "grafana/grafana:8.5.6"
          port {
            container_port = var.grafana_within_cluster_port
          }
          volume_mount {
            name       = "grafana-config"
            mount_path = "/etc/grafana/provisioning/datasources"
          }
        }
        volume {
          name = "grafana-config"
          config_map {
            name = "grafana-config"
          }
        }
      }
    }
  }
}


resource "kubernetes_service" "grafana" {
  depends_on = [
    kubernetes_deployment.grafana
  ]
  metadata {
    name      = "grafana"
    namespace = var.monitoring_namespace
  }
  spec {
    selector = {
      app = "${kubernetes_deployment.grafana.metadata.0.labels.app}"
    }
    port {
      port        = var.grafana_within_cluster_port
      target_port = 3000
      node_port   = var.grafana_port
    }
    type = "NodePort"
  }
}