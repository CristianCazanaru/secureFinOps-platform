terraform {
  required_providers {
    docker = {
      source  = "kreuzwerker/docker"
      version = "~> 3.0"
    }
  }
}

resource "docker_image" "jenkins" {
  name = "securefinops-jenkins:local"
  build {
    context    = path.module
    dockerfile = "Dockerfile"
  }

  triggers = {
    dockerfile_sha1 = filesha1("${path.module}/Dockerfile")
    entrypoint_sha1 = filesha1("${path.module}/scripts/entrypoint.sh")
  }
  keep_locally = true
}

resource "docker_volume" "jenkins_home" {
  name = "securefinops-jenkins-home-${var.environment}"

  lifecycle {
    prevent_destroy = true
  }
}

resource "docker_container" "jenkins" {
  name  = "securefinops-jenkins-${var.environment}"
  image = docker_image.jenkins.image_id

  ports {
    internal = 8080
    external = var.jenkins_port
  }

  ports {
    internal = 50000
    external = 50000
  }

  volumes {
    volume_name    = docker_volume.jenkins_home.name
    container_path = "/var/jenkins_home"
  }

  volumes {
    host_path      = "/var/run/docker.sock"
    container_path = "/var/run/docker.sock"
  }

  networks_advanced {
    name = var.network_name
  }

  restart = "unless-stopped"
}