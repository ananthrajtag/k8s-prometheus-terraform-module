provider "helm" {
  version = "~> 0.6"
  namespace = "kube-system"
  service_account = "tiller"
  override = ["spec.template.spec.automountserviceaccounttoken=true"]

  kubernetes {
    #client_certificate     = "${var.client_certificate}"
    #client_key             = "${var.client_key}"
    cluster_ca_certificate = "${var.cluster_ca_certificate}"
    host                   = "${var.host}"
    token                  = "${var.token}"
  }
}

resource "helm_release" "prometheus_operator" {
  name  = "monitoring"
  chart = "stable/prometheus-operator"
  namespace = "monitoring"

  values = [
    "${file("${path.module}/monitoring/prometheus/values.yml")}",
  ]
}
