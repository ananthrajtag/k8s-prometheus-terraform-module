provider "google" {
  credentials = "${file("${var.config_file}")}"
  #credentials = "${base64decode(var.google_creds_base64)}"
  project = "${var.projet_name}"
}

resource "google_container_cluster" "primary" {
  name = "${var.cluster_name}-cluster"
  project = "${var.projet_name}"
  initial_node_count       = 1
  remove_default_node_pool = true
  min_master_version = "1.11.8-gke.6"
  node_version = "1.11.8-gke.6"
  zone       = "${var.region}"

  node_config {
    machine_type = "${var.machine_type}"
    oauth_scopes = [
      "https://www.googleapis.com/auth/compute",
      "https://www.googleapis.com/auth/devstorage.read_only",
      "https://www.googleapis.com/auth/logging.write",
      "https://www.googleapis.com/auth/monitoring",
    ]
  }
}

resource "random_id" "np" {
  byte_length = 11
  prefix      = "${var.cluster_name}-"

  keepers = {
    machine_type = "${var.machine_type}"
  }
}

resource "google_container_node_pool" "cluster_nodes" {
  project    = "${var.projet_name}"
  name       = "${random_id.np.dec}"
  zone       = "${var.region}"
  cluster    = "${google_container_cluster.primary.name}"
  node_count = 1
  version    = "1.11.8-gke.6"

  node_config {
    machine_type = "${var.machine_type}"
  }

  lifecycle {
    create_before_destroy = true
  }
}

data "template_file" "kubeconfig" {
  template = "${file("${path.module}/template/kubeconfig.cert.tpl")}"

  vars {
    cluster_name               = "${google_container_cluster.primary.name}"
    certificate_authority_data = "${google_container_cluster.primary.0.master_auth.0.cluster_ca_certificate}"
    server                     = "https://${google_container_cluster.primary.0.endpoint}"
    client_cert                = "${google_container_cluster.primary.0.master_auth.0.client_certificate}"
    client_key                 = "${google_container_cluster.primary.0.master_auth.0.client_key}"
  }
}

resource "local_file" "kubeconfig" {
  content  = "${data.template_file.kubeconfig.rendered}"
  filename = "${path.module}/kubeconfig"
}
