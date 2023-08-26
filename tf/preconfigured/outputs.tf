output "repository_urls" {
  value = [
  for obj in aws_ecr_repository.app:
  {
    name = obj.name
    url = obj.repository_url
  }
  ]
}

output "region" {
  value = var.region
}

output "ecs_cluster_name" {
  value = var.cluster_name
}

