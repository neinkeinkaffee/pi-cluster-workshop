provider "kubernetes" {
}

resource "kubernetes_namespace" "test" {
  metadata {
    name = "test"
  }
}