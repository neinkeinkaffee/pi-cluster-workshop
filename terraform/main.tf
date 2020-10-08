provider "kubernetes" {
}

resource "kubernetes_namespace" "cluster" {
  metadata {
    name = var.namespace
  }
}

resource "kubernetes_deployment" "nginx" {
  metadata {
    name      = "nginx"
    namespace = kubernetes_namespace.cluster.metadata[0].name
    labels = {
      app = "nginx"
    }
  }
  spec {
    replicas = 3
    selector {
      match_labels = {
        app = "nginx"
      }
    }
    template {
      metadata {
        labels = {
          app = "nginx"
        }
      }
      spec {
        container {
          image = "nginx"
          name  = "hello-nginx"
          port {
            container_port = 80
          }
        }
      }
    }
  }
}

resource "kubernetes_service" "nginx" {
  metadata {
    name = "nginx"
    namespace = kubernetes_namespace.cluster.metadata[0].name
  }
  spec {
    selector = {
      app = kubernetes_deployment.nginx.metadata[0].labels.app
    }
    session_affinity = "ClientIP"
    port {
      port        = 8080
      target_port = 80
    }

    type = "LoadBalancer"
  }
}

resource "kubernetes_ingress" "ingress" {
  metadata {
    name = "example-ingress"
    namespace = kubernetes_namespace.cluster.metadata[0].name
  }

  spec {
    backend {
      service_name = kubernetes_service.nginx.metadata[0].name
      service_port = kubernetes_service.nginx.spec[0].port[0].port
    }
  }
}
