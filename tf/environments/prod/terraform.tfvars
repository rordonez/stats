environment      = "prod"
application_name = "hello-world"
services =  [
  {
    name = "stats-frontend"
    container = {
      port      = 3000
      host_port = 3000
      memory    = 512
      cpu       = 256
      environment = {
        REACT_APP_BACKEND_SERVICE_URL = "http://stats-backend:8080"
      }
    }
    replicas = 2
    proxy = true
  },
  {
    name = "stats-backend"
    container = {
      port      = 8080
      host_port = 8080
      memory    = 512
      cpu       = 256
      environment = {}
    }
    replicas = 2
    proxy = false
  },
]
region = "us-east-1"
ecs_cluster_name = "ecs-prod-cluster"
