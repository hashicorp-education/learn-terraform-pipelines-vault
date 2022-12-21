terraform {
  backend "remote" {
    organization = "terraform201-ob"

    workspaces {
      name = "learn-terraform-pipelines-vault"
    }
  }
  required_providers {
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.0.2"
    }
  }

  required_version = "~> 1.3.5"
}

data "terraform_remote_state" "cluster" {
  backend = "remote"
  config = {
    organization = var.organization
    workspaces = {
      name = var.cluster_workspace
    }
  }
}

data "terraform_remote_state" "consul" {
  backend = "remote"
  config = {
    organization = var.organization
    workspaces = {
      name = var.consul_workspace
    }
  }
}


# Retrieve GKE cluster information
provider "google" {
  project = data.terraform_remote_state.cluster.outputs.project_id
  region  = data.terraform_remote_state.cluster.outputs.region
  credentials = file("hc-cc1d107e30744a2085d0ecb8c5b-53d1a4a1d258.json")
}

data "google_client_config" "default" {}

data "google_container_cluster" "my_cluster" {
  name     = data.terraform_remote_state.cluster.outputs.cluster
  location = data.terraform_remote_state.cluster.outputs.region
}

provider "kubernetes" {
  host                   = data.terraform_remote_state.cluster.outputs.host
  token                  = data.google_client_config.default.access_token
  cluster_ca_certificate = data.terraform_remote_state.cluster.outputs.cluster_ca_certificate

}

provider "helm" {
  kubernetes {
    host                   = data.terraform_remote_state.cluster.outputs.host
    token                  = data.google_client_config.default.access_token
    cluster_ca_certificate = data.terraform_remote_state.cluster.outputs.cluster_ca_certificate
  }
}
