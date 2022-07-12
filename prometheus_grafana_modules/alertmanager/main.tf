resource "kubernetes_config_map" "alertmanager" {
  metadata {
    name      = "alertmanager-config"
    namespace = var.monitoring_namespace
  }
  data = {
    "config.yml" = <<eof
    global:
    templates:
    - '/etc/alertmanager/*.tmpl'
    route:
      receiver: 'gmail-notifications'
    receivers:
    - name: 'gmail-notifications'
      email_configs:
      - to: ${var.alertmanager_toemail}
        from: ${var.alertmanager_fromemail}
        smarthost: ${var.alertmanager_host}
        auth_username: ${var.alertmanager_fromemail}
        auth_identity: ${var.alertmanager_fromemail}
        auth_password: ${var.alertmanager_password}
        send_resolved: true   
  eof
  }
}


resource "kubernetes_deployment" "alertmanager" {
  metadata {
    name      = "alertmanager"
    namespace = var.monitoring_namespace
    labels = {
      app = "alertmanager"
    }
  }
  spec {
    selector {
      match_labels = {
        app = "alertmanager"
      }
    }
    template {
      metadata {
        labels = {
          app = "alertmanager"
        }
      }
      spec {
        container {
          name  = "alertmanager"
          image = "prom/alertmanager:v0.24.0"
          args  = ["--config.file=/etc/alertmanager/config.yml"]
          port {
            container_port = var.alertmanager_within_cluster_port
          }
          volume_mount {
            name       = "alertmanager-config"
            mount_path = "/etc/alertmanager"
          }
        }
        volume {
          name = "alertmanager-config"
          config_map {
            name = "alertmanager-config"
          }
        }
      }
    }
  }
}


resource "kubernetes_service" "alertmanager" {
  depends_on = [
    kubernetes_deployment.alertmanager
  ]
  metadata {
    name      = "alertmanager"
    namespace = var.monitoring_namespace
  }
  spec {
    selector = {
      app = "${kubernetes_deployment.alertmanager.metadata.0.labels.app}"
    }
    port {
      port        = var.alertmanager_within_cluster_port
      target_port = 9093
      node_port   = var.alertmanager_port
    }
    type = "NodePort"
  }
}