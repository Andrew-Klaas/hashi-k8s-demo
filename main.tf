terraform {
  required_version = ">= 0.11.0"
}

provider "google" {
  //Use the credentials file or environment variables
  //https://www.terraform.io/docs/providers/google/provider_reference.html
  //credentials = "${file("gcp-creds.json")}"
  project     = "${var.gcp_project}"
  region      = "${var.gcp_region}"
}

resource "google_container_cluster" "k8sexample" {
  name               = "${var.cluster_name}"
  description        = "k8s demo cluster"
  location           = "${var.gcp_zone}"
  initial_node_count = "${var.initial_node_count}"
  enable_legacy_abac = "true"

  master_auth {
    username = "${var.master_username}"
    password = "${var.master_password}"
  }

  node_config {
    machine_type = "${var.node_machine_type}"
    disk_size_gb = "${var.node_disk_size}"
    oauth_scopes = [
      "https://www.googleapis.com/auth/compute",
      "https://www.googleapis.com/auth/devstorage.read_only",
      "https://www.googleapis.com/auth/logging.write",
      "https://www.googleapis.com/auth/monitoring"
    ]
  }
}

resource "google_compute_instance" "mariadb" {
  name         = "${var.cluster_name}-mariadb-vm"
  machine_type = "n1-standard-1"
  zone         = "${var.gcp_zone}"

  boot_disk {
    initialize_params {
      image = "ubuntu-os-cloud/ubuntu-1804-lts"
    }
  }
  
  // Local SSD disk
  scratch_disk {
    interface = "SCSI"
  }

  network_interface {
    network = "default"

    access_config {
      // Ephemeral IP
    }
  }

  //install mariadb, consul, envoy, etc.
  metadata_startup_script = "${data.template_file.mariadb-template.rendered}"

  metadata = {
   ssh-keys = "${var.ssh_user}:${file("~/.ssh/id_rsa.pub")}"
  }
}

data "template_file" "mariadb-template" {
  template = "${file("${path.module}/init-mariadb.tpl")}"

  vars = {
    environment_name                 = "${var.cluster_name}"
  }
}

resource "google_compute_firewall" "mariadb-firewalls" {
  name    = "${var.cluster_name}-mariadb-vm-firewall-rules"
  network = "default"
  direction = "INGRESS"
  source_ranges = ["0.0.0.0/0"]

  allow {
    protocol = "icmp"
  }

  allow {
    protocol = "tcp"
    ports    = ["80", "22", "3306", "443", "8443"]
  }

  allow { 
    protocol = "tcp"
    ports    = ["8500", "8501", "8600", "8502", "8301", "8302", "8300", "21000-21255" ]
    // internal network traffic envoy to consul
  }
}
