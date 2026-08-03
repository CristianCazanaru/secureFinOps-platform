terraform {
  required_version = ">= 1.5.0"
  required_providers {
    docker = {
      source  = "kreuzwerker/docker"
      version = "~> 3.0"
    }
  }
}

provider "docker" {}

module "postgres" {
  source = "../../modules/postgresql"

  environment = "local"
  db_name     = var.db_name
  db_user     = var.db_user
  db_password = var.db_password
  db_port     = 5432
}

module "jenkins" {
  source = "../../modules/jenkins"
  
  environment  = "local"
  jenkins_port = var.jenkins_port
  network_name = module.postgres.network_name
} 

module "sonarqube" {
  source         = "../../modules/sonarqube"
  environment    = "local"
  sonarqube_port = 9090
  network_name   = module.postgres.network_name
}