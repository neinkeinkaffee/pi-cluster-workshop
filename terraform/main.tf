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

//spec:
//tls:
//- hosts:
//- kube.mydomain.com
//secretName: tls-secret
//rules:
//- host: kube.mydomain.com
//http:
//paths:
//- path: /
//backend:
//serviceName: kubernetes-dashboard
//servicePort: 443


resource "kubernetes_ingress" "ingress" {
  metadata {
    name = "example-ingress"
    namespace = kubernetes_namespace.kubernetes_dashboard.metadata[0].name
  }

  spec {
    rule {
      http {
        path {
          path = "/"
          backend {
            service_name = kubernetes_service.kubernetes_dashboard.metadata[0].name
            service_port = kubernetes_service.kubernetes_dashboard.spec[0].port[0].port
          }
        }
      }
    }
  }
}
