resource "kubernetes_cluster_role" "prometheus" {
  metadata {
    name = "prometheus"
  }
  rule {
    api_groups = [""]
    resources  = ["nodes", "pods", "services", "endpoints"]
    verbs      = ["get", "list", "watch"]
  }
  rule {
    api_groups = ["non_resource_urls"]
    resources  = ["/metrics"]
    verbs      = ["get"]
  }
}


resource "kubernetes_cluster_role_binding" "prometheus" {
  metadata {
    name = "prometheus"
  }
  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = kubernetes_cluster_role.prometheus.metadata.0.name
  }
  subject {
    kind      = "ServiceAccount"
    name      = "default"
    namespace = var.monitoring_namespace
  }
}


resource "kubernetes_config_map" "prometheus" {
  metadata {
    name      = "prometheus-config"
    namespace = var.monitoring_namespace
  }
  data = {
    "prometheus-config.yml" = <<eof
    global:
      scrape_interval: 10s
      scrape_timeout: 10s
      evaluation_interval: 10s
    rule_files:
      - /prometheus/prometheus.rules
    alerting:
      alertmanagers:
      - scheme: http
        static_configs:
        - targets:
          - "alertmanager.monitoring.svc:${var.alertmanager_within_cluster_port}"
    scrape_configs:
      - job_name: 'metrics-server'
        static_configs:
          - targets: ['metrics-server.kube-system.svc.cluster.local:${var.metrics_within_cluster_port}']
          eof
  }
}


resource "kubernetes_config_map" "prometheus-rules" {
  metadata {
    name      = "prometheus-rules"
    namespace = var.monitoring_namespace
  }
  data = { # Kubernetes alert rules. You can find more rules at https://awesome-prometheus-alerts.grep.to/rules.html#kubernetes
    "prometheus.rules" = <<eof
    groups:
    - name: k8s alerts
      rules:
      - alert: KubernetesNodeReady
        expr: kube_node_status_condition{condition="Ready",status="true"} == 0
        for: 10m
        labels:
          severity: critical
        annotations:
          summary: Kubernetes Node ready (instance {{ $labels.instance }})
          description: "Node {{ $labels.node }} has been not ready for more than 10 minutes\n  VALUE = {{ $value }}\n  LABELS = {{ $labels }}"

      - alert: KubernetesOutOfCapacity
        expr: sum by (node) ((kube_pod_status_phase{phase="Running"} == 1) + on(uid) group_left(node) (0 * kube_pod_info{pod_template_hash=""})) / sum by (node) (kube_node_status_allocatable{resource="pods"}) * 100 > 90
        for: 1m
        labels:
          severity: warning
        annotations:
          summary: Kubernetes out of capacity (instance {{ $labels.instance }})
          description: "{{ $labels.node }} is out of capacity\n  VALUE = {{ $value }}\n  LABELS = {{ $labels }}"

      - alert: KubernetesMemoryPressure
        expr: kube_node_status_condition{condition="MemoryPressure",status="true"} == 1
        for: 1m
        labels:
          severity: critical
        annotations:
          summary: Kubernetes memory pressure (instance {{ $labels.instance }})
          description: "{{ $labels.node }} is under MemoryPressure\n  VALUE = {{ $value }}\n  LABELS = {{ $labels }}"

      - alert: KubernetesDiskPressure
        expr: kube_node_status_condition{condition="DiskPressure",status="true"} == 1
        for: 2m
        labels:
          severity: critical
        annotations:
          summary: Kubernetes disk pressure (instance {{ $labels.instance }})
          description: "{{ $labels.node }} is under DiskPressure\n  VALUE = {{ $value }}\n  LABELS = {{ $labels }}"

      - alert: KubernetesPodNotHealthy
        expr: min_over_time(sum by (namespace, pod) (kube_pod_status_phase{phase=~"Pending|Unknown|Failed"})[15m:1m]) > 0
        for: 10m
        labels:
          severity: critical
        annotations:
          summary: Kubernetes Pod not healthy (instance {{ $labels.instance }})
          description: "Pod has been in a non-ready state for longer than 10 minutes.\n  VALUE = {{ $value }}\n  LABELS = {{ $labels }}"

      - alert: KubernetesPodCrashLooping
        expr: increase(kube_pod_container_status_restarts_total[1m]) > 3
        for: 2m
        labels:
          severity: warning
        annotations:
          summary: Kubernetes pod crash looping (instance {{ $labels.instance }})
          description: "Pod {{ $labels.pod }} is crash looping\n  VALUE = {{ $value }}\n  LABELS = {{ $labels }}"
    eof
  }
}


resource "kubernetes_deployment" "prometheus" {
  depends_on = [
    kubernetes_config_map.prometheus,
  ]
  metadata {
    name      = "prometheus"
    namespace = var.monitoring_namespace
    labels = {
      app = "prometheus"
    }
  }
  spec {
    selector {
      match_labels = {
        app = "prometheus"
      }
    }
    template {
      metadata {
        labels = {
          app = "prometheus"
        }
      }
      spec {
        container {
          name  = "prometheus"
          image = "prom/prometheus:v2.36.2"
          args  = ["--config.file=prometheus-config.yml", "--storage.tsdb.retention.time=7d"]
          port {
            container_port = var.metrics_within_cluster_port
          }
          volume_mount {
            name       = "prometheus-config"
            mount_path = "/prometheus/prometheus-config.yml"
            sub_path   = "prometheus-config.yml"
          }
          volume_mount {
            name       = "prometheus-rules"
            mount_path = "/prometheus/prometheus.rules"
            sub_path   = "prometheus.rules"
          }
          volume_mount {
            name       = "prometheus-data"
            mount_path = "/prometheus/data/" #by default prometheus writes its database here
          }
        }
        volume {
          name = "prometheus-config"
          config_map {
            name = "prometheus-config"
          }
        }
        volume {
          name = "prometheus-rules"
          config_map {
            name = "prometheus-rules"
          }
        }
        volume {
          name = "prometheus-data"
          empty_dir {}
        }
      }
    }
  }
}


resource "kubernetes_service" "prometheus" {
  depends_on = [
    kubernetes_deployment.prometheus
  ]
  metadata {
    name      = "prometheus"
    namespace = var.monitoring_namespace
  }
  spec {
    selector = {
      app = "${kubernetes_deployment.prometheus.metadata.0.labels.app}"
    }
    port {
      port        = var.prometheus_within_cluster_port
      target_port = 9090
      node_port   = var.prometheus_port
    }
    type = "NodePort"
  }
}


resource "kubernetes_deployment" "metrics" {
  metadata {
    name      = "metrics-server"
    namespace = "kube-system"
    labels = {
      app = "metrics-server"
    }
  }
  spec {
    selector {
      match_labels = {
        app = "metrics-server"
      }
    }
    template {
      metadata {
        labels = {
          app = "metrics-server"
        }
      }
      spec {
        container {
          name  = "metrics-server"
          image = "k8s.gcr.io/kube-state-metrics/kube-state-metrics:v2.5.0"
          port {
            container_port = var.metrics_within_cluster_port
          }
        }
      }
    }
  }
}


resource "kubernetes_service" "metrics" {
  metadata {
    name      = "metrics-server"
    namespace = "kube-system"
    labels = {
      app = "${kubernetes_deployment.metrics.metadata.0.labels.app}"
    }
  }
  spec {
    selector = {
      app = "${kubernetes_deployment.metrics.metadata.0.labels.app}"
    }
    type = "ClusterIP"
    port {
      port        = var.metrics_within_cluster_port
      target_port = 8080
    }
  }
}