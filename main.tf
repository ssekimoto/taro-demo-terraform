resource "google_compute_network" "ws_network" {
  name                    = "ws-vpc"
  auto_create_subnetworks = false
}

resource "google_compute_subnetwork" "ws_subnet" {
  name          = "ws-subnet"
  ip_cidr_range = "10.0.1.0/24"
  region        = var.region
  network       = google_compute_network.ws_network.id

  private_ip_google_access = true
}

resource "google_compute_router" "ws_router" {
  name    = "ws-router"
  region  = var.region
  network = google_compute_network.ws_network.id
}

resource "google_compute_router_nat" "ws_nat" {
  name   = "ws-nat"
  router = google_compute_router.ws_router.name
  region = var.region

  nat_ip_allocate_option             = "AUTO_ONLY"
  source_subnetwork_ip_ranges_to_nat = "LIST_OF_SUBNETWORKS"

  subnetwork {
    name                    = google_compute_subnetwork.ws_subnet.id
    source_ip_ranges_to_nat = ["ALL_IP_RANGES"]
  }

  log_config {
    enable = true
    filter = "ERRORS_ONLY"
  }
}

resource "google_project_service" "workstations" {
  service                    = "workstations.googleapis.com"
  disable_dependent_services = false
  disable_on_destroy         = false
}

resource "google_workstations_workstation_cluster" "ws_cluster" {
  provider = google-beta

  workstation_cluster_id = "ws-cluster-${var.region}"
  network                = google_compute_network.ws_network.id
  subnetwork             = google_compute_subnetwork.ws_subnet.id
  location               = var.region

  depends_on = [
    google_compute_router_nat.ws_nat,
    google_project_service.workstations
  ]
}

resource "google_workstations_workstation_config" "ws_config" {
  provider = google-beta

  workstation_config_id  = "ws-config-default"
  workstation_cluster_id = google_workstations_workstation_cluster.ws_cluster.workstation_cluster_id
  location               = var.region

  idle_timeout = "28800s"

  host {
    machine_type = "e2-standard-4" // 4vCPU, 16GB RAM
  }

  container {
    image = "us-central1-docker.pkg.dev/cloud-workstations-images/predefined/code-oss-c-go:latest"
  }

  persistent_directories {
    mount_path = "/home"
    gce_pd {
      size_gb    = 200
      fs_type    = "ext4"
      disk_type  = "pd-standard"
      reclaim_policy = "DELETE"
    }
  }

  iam_policy {
    bindings {
      role = "roles/workstations.workstationUser"
      members = [
        var.workstation_user_email
      ]
    }
  }
}

resource "google_workstations_workstation" "ws_instance" {
  provider = google-beta

  workstation_id         = "enter-username"
  workstation_config_id  = google_workstations_workstation_config.ws_config.workstation_config_id
  workstation_cluster_id = google_workstations_workstation_cluster.ws_cluster.workstation_cluster_id
  location               = var.region

  iam_policy {
    bindings {
      role = "roles/workstations.workstationOwner"
      members = [
        var.workstation_user_email
      ]
    }
  }
}
