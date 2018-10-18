#ECR repository
resource "aws_ecr_repository" "web_docker" {
  name = "web-docker"
}

output "aws_ecr_repository_web_docker_repository_url" {
  value = "${aws_ecr_repository.web_docker.repository_url}"
}
