resource "kubernetes_namespace" "kubernetes_dashboard" {
  metadata {
    name = "kubernetes-dashboard"
  }
}

resource "kubernetes_service_account" "kubernetes_dashboard" {
  metadata {
    name      = "kubernetes-dashboard"
    namespace = "kubernetes-dashboard"

    labels = {
      k8s-app = "kubernetes-dashboard"
    }
  }
  automount_service_account_token = true
}

resource "kubernetes_service" "kubernetes_dashboard" {
  metadata {
    name      = "kubernetes-dashboard"
    namespace = "kubernetes-dashboard"

    labels = {
      k8s-app = "kubernetes-dashboard"
    }
  }

  spec {
    port {
      port        = 80
      target_port = "9090"
    }

    selector = {
      k8s-app = "kubernetes-dashboard"
    }
  }
}

resource "kubernetes_secret" "kubernetes_dashboard_csrf" {
  metadata {
    name      = "kubernetes-dashboard-csrf"
    namespace = "kubernetes-dashboard"

    labels = {
      k8s-app = "kubernetes-dashboard"
    }
  }

  type = "Opaque"
}

resource "kubernetes_secret" "kubernetes_dashboard_key_holder" {
  metadata {
    name      = "kubernetes-dashboard-key-holder"
    namespace = "kubernetes-dashboard"

    labels = {
      k8s-app = "kubernetes-dashboard"
    }
  }

  type = "Opaque"
}

resource "kubernetes_config_map" "kubernetes_dashboard_settings" {
  metadata {
    name      = "kubernetes-dashboard-settings"
    namespace = "kubernetes-dashboard"

    labels = {
      k8s-app = "kubernetes-dashboard"
    }
  }
}

resource "kubernetes_role" "kubernetes_dashboard" {
  metadata {
    name      = "kubernetes-dashboard"
    namespace = "kubernetes-dashboard"

    labels = {
      k8s-app = "kubernetes-dashboard"
    }
  }

  rule {
    verbs          = ["get", "update", "delete"]
    api_groups     = [""]
    resources      = ["secrets"]
    resource_names = ["kubernetes-dashboard-key-holder", "kubernetes-dashboard-certs", "kubernetes-dashboard-csrf"]
  }

  rule {
    verbs          = ["get", "update"]
    api_groups     = [""]
    resources      = ["configmaps"]
    resource_names = ["kubernetes-dashboard-settings"]
  }

  rule {
    verbs          = ["proxy"]
    api_groups     = [""]
    resources      = ["services"]
    resource_names = ["heapster", "dashboard-metrics-scraper"]
  }

  rule {
    verbs          = ["get"]
    api_groups     = [""]
    resources      = ["services/proxy"]
    resource_names = ["heapster", "http:heapster:", "https:heapster:", "dashboard-metrics-scraper", "http:dashboard-metrics-scraper"]
  }
}

resource "kubernetes_cluster_role" "kubernetes_dashboard" {
  metadata {
    name = "kubernetes-dashboard"

    labels = {
      k8s-app = "kubernetes-dashboard"
    }
  }

  rule {
    verbs      = ["get", "list", "watch"]
    api_groups = ["metrics.k8s.io"]
    resources  = ["pods", "nodes"]
  }
}

resource "kubernetes_role_binding" "kubernetes_dashboard" {
  metadata {
    name      = "kubernetes-dashboard"
    namespace = "kubernetes-dashboard"

    labels = {
      k8s-app = "kubernetes-dashboard"
    }
  }

  subject {
    kind      = "ServiceAccount"
    name      = "kubernetes-dashboard"
    namespace = "kubernetes-dashboard"
  }

  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "Role"
    name      = "kubernetes-dashboard"
  }
}

resource "kubernetes_cluster_role_binding" "kubernetes-readonly" {
  metadata {
    name = "kubernetes-dashboard-readonly"

    labels = {
      k8s-app = "kubernetes-dashboard-readonly"
    }
  }

  subject {
    kind      = "ServiceAccount"
    name      = kubernetes_service_account.kubernetes_dashboard.metadata[0].name
    namespace = kubernetes_namespace.kubernetes_dashboard.metadata[0].name
  }

  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = "dashboard-viewonly"
  }
}


resource "kubernetes_cluster_role_binding" "kubernetes_dashboard" {
  metadata {
    name = "kubernetes-dashboard"
  }

  subject {
    kind      = "ServiceAccount"
    name      = "kubernetes-dashboard"
    namespace = "kubernetes-dashboard"
  }

  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = "kubernetes-dashboard"
  }
}

resource "kubernetes_deployment" "kubernetes_dashboard" {
  metadata {
    name      = "kubernetes-dashboard"
    namespace = "kubernetes-dashboard"

    labels = {
      k8s-app = "kubernetes-dashboard"
    }
  }

  spec {
    replicas = 1

    selector {
      match_labels = {
        k8s-app = "kubernetes-dashboard"
      }
    }

    template {
      metadata {
        labels = {
          k8s-app = "kubernetes-dashboard"
        }
      }

      spec {
        volume {
          name = "tmp-volume"
        }
        automount_service_account_token = true

        container {
          name  = "kubernetes-dashboard"
          image = "kubernetesui/dashboard:v2.0.4"
          args  = ["--namespace=kubernetes-dashboard", "--enable-insecure-login"]

          port {
            container_port = 9090
            protocol       = "TCP"
          }

          volume_mount {
            name       = "tmp-volume"
            mount_path = "/tmp"
          }

          liveness_probe {
            http_get {
              path = "/"
              port = "9090"
            }

            initial_delay_seconds = 30
            timeout_seconds       = 30
          }

          security_context {
            run_as_user               = 1001
            run_as_group              = 2001
            read_only_root_filesystem = true
          }
        }

        node_selector = {
          "kubernetes.io/os" = "linux"
        }

        service_account_name = "kubernetes-dashboard"

        toleration {
          key    = "node-role.kubernetes.io/master"
          effect = "NoSchedule"
        }
      }
    }

    revision_history_limit = 10
  }
}

resource "kubernetes_service" "dashboard_metrics_scraper" {
  metadata {
    name      = "dashboard-metrics-scraper"
    namespace = "kubernetes-dashboard"

    labels = {
      k8s-app = "dashboard-metrics-scraper"
    }
  }

  spec {
    port {
      port        = 8000
      target_port = "8000"
    }

    selector = {
      k8s-app = "dashboard-metrics-scraper"
    }
  }
}

resource "kubernetes_deployment" "dashboard_metrics_scraper" {
  metadata {
    name      = "dashboard-metrics-scraper"
    namespace = "kubernetes-dashboard"

    labels = {
      k8s-app = "dashboard-metrics-scraper"
    }
  }

  spec {
    replicas = 1

    selector {
      match_labels = {
        k8s-app = "dashboard-metrics-scraper"
      }
    }

    template {
      metadata {
        labels = {
          k8s-app = "dashboard-metrics-scraper"
        }

        annotations = {
          "seccomp.security.alpha.kubernetes.io/pod" = "runtime/default"
        }
      }

      spec {
        volume {
          name = "tmp-volume"
        }
        automount_service_account_token = true
        container {
          name  = "dashboard-metrics-scraper"
          image = "kubernetesui/metrics-scraper:v1.0.4"

          port {
            container_port = 8000
            protocol       = "TCP"
          }

          volume_mount {
            name       = "tmp-volume"
            mount_path = "/tmp"
          }

          liveness_probe {
            http_get {
              path   = "/"
              port   = "8000"
              scheme = "HTTP"
            }

            initial_delay_seconds = 30
            timeout_seconds       = 30
          }

          security_context {
            run_as_user               = 1001
            run_as_group              = 2001
            read_only_root_filesystem = true
          }
        }

        node_selector = {
          "kubernetes.io/os" = "linux"
        }

        service_account_name = "kubernetes-dashboard"

        toleration {
          key    = "node-role.kubernetes.io/master"
          effect = "NoSchedule"
        }
      }
    }

    revision_history_limit = 10
  }
}

resource "kubernetes_cluster_role" "dashboard_viewonly" {
  metadata {
    name = "dashboard-viewonly"
  }

  rule {
    verbs      = ["get", "list", "watch"]
    api_groups = [""]
    resources  = ["configmaps", "endpoints", "persistentvolumeclaims", "pods", "replicationcontrollers", "replicationcontrollers/scale", "serviceaccounts", "services", "nodes", "persistentvolumeclaims", "persistentvolumes"]
  }

  rule {
    verbs      = ["get", "list", "watch"]
    api_groups = [""]
    resources  = ["bindings", "events", "limitranges", "namespaces/status", "pods/log", "pods/status", "replicationcontrollers/status", "resourcequotas", "resourcequotas/status"]
  }

  rule {
    verbs      = ["get", "list", "watch"]
    api_groups = [""]
    resources  = ["namespaces"]
  }

  rule {
    verbs      = ["get", "list", "watch"]
    api_groups = ["apps"]
    resources  = ["daemonsets", "deployments", "deployments/scale", "replicasets", "replicasets/scale", "statefulsets"]
  }

  rule {
    verbs      = ["get", "list", "watch"]
    api_groups = ["autoscaling"]
    resources  = ["horizontalpodautoscalers"]
  }

  rule {
    verbs      = ["get", "list", "watch"]
    api_groups = ["batch"]
    resources  = ["cronjobs", "jobs"]
  }

  rule {
    verbs      = ["get", "list", "watch"]
    api_groups = ["extensions"]
    resources  = ["daemonsets", "deployments", "deployments/scale", "ingresses", "networkpolicies", "replicasets", "replicasets/scale", "replicationcontrollers/scale"]
  }

  rule {
    verbs      = ["get", "list", "watch"]
    api_groups = ["policy"]
    resources  = ["poddisruptionbudgets"]
  }

  rule {
    verbs      = ["get", "list", "watch"]
    api_groups = ["networking.k8s.io"]
    resources  = ["networkpolicies"]
  }

  rule {
    verbs      = ["get", "list", "watch"]
    api_groups = ["storage.k8s.io"]
    resources  = ["storageclasses", "volumeattachments"]
  }

  rule {
    verbs      = ["get", "list", "watch"]
    api_groups = ["rbac.authorization.k8s.io"]
    resources  = ["clusterrolebindings", "clusterroles", "roles", "rolebindings"]
  }
}

