provider "kubernetes" {}

resource "kubernetes_namespace" "cluster" {
  metadata {
    name = var.namespace
  }
}

provider "helm" {
  kubernetes {}
}
