module "service" {
  source = "./modules/app"

  application_name    = var.application_name
  application_version = var.application_version
  services            = var.services
  ecs_cluster_name    = var.ecs_cluster_name
  environment         = var.environment
  region              = var.region
}

output "service_url" {
  value = module.service.app_url
}