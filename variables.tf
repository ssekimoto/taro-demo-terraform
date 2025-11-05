terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = ">= 5.0.0"
    }
    google-beta = {
      source  = "hashicorp/google-beta"
      version = ">= 5.0.0"
    }
  }
}

provider "google" {
  project = var.project_id
  region  = var.region
}

provider "google-beta" {
  project = var.project_id
  region  = var.region
}

variable "project_id" {
  description = "GCP プロジェクト ID"
  type        = string
}

variable "region" {
  description = "リソースをデプロイするリージョン"
  type        = string
  default     = "asia-northeast1"
}

variable "zone" {
  description = "リソースをデプロイするゾーン"
  type        = string
  default     = "asia-northeast1-a"
}

variable "workstation_user_email" {
  description = "ワークステーションの所有者となるユーザーのメールアドレス（IAM 形式）"
  type        = string
  example     = "user:user@example.com"
}
