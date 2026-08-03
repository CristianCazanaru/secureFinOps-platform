output "sonarqube_url" {
  value = "http://localhost:${var.sonarqube_port}"
}

output "container_name" {
  value = docker_container.sonarqube.name
}