variable "environment" {
  description = "Name of the environment"
  type        = string
  validation {
    condition     = contains(["dev", "prod", "staging"], var.environment)
    error_message = "Environment can only be \"dev\", \"staging\" or \"prod\""
  }
}

variable "application_name" {
  description = "Name of the application"
  type        = string
}

variable "application_version" {
  description = "Application version"
  type = string
}

variable "services" {
  description = "List of service definitions"
  type = list(object({
    name = string
    container = object({
      port        = number
      host_port   = number
      memory      = number
      cpu         = number
      environment = map(string)
    })
    replicas = string
    proxy = bool
  }))
}

variable "ecs_cluster_name" {
  description = "ECS cluster name"
  type        = string
}

variable "region" {
  description = "AWS region"
  default     = "us-east-1"
  type        = string
}

