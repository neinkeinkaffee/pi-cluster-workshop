resource "kubernetes_namespace" "cert_manager" {
  metadata {
    name = "cert-manager"
  }
}

resource "helm_release" "cert_manager" {
  name = "cert-manager"
  repository = "https://charts.jetstack.io"
  chart = "cert-manager"
  namespace = "cert-manager"

  set {
    name = "installCRDs"
    value = "true"
  }
}

resource "cluster_issuer" "letsencrypt-staging" {
  metadata {
    name = "letsencrypt-staging"
  }

  spec {
      acme {
        server = "https://acme-staging-v02.api.letsencrypt.org/directory"
        email = "gesa.stupperich@gmail.com"
        privateKeySecretRef {
          name = "letsencrypt-staging"
        }
        solvers = {
            http01 = {
              ingress = {
                class = "traefik"
              }
            }
        }
      }
  }
}


