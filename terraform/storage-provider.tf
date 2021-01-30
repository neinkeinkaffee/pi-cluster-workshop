resource "helm_release" "nfs-client-provisioner" {
  name = "nfs-client-provisioner"
  repository = "https://charts.helm.sh/stable"
  chart = "nfs-client-provisioner"
  namespace = "kube-system"

  set {
    name = "image.repository"
    value = "quay.io/external_storage/nfs-client-provisioner-arm"
  }

  set {
    name = "nfs.server"
    value = "10.0.0.1"
  }

  set {
    name = "nfs.path"
    value = "/mnt/sda1"
  }

  set {
    name = "storage_class.archive_on_delete"
    value = "false"
  }
}
