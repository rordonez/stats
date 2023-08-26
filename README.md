# Task 1 - Dockerize the Application

I have created 3 containers:
 * `api` for the [python](api/Dockerfile) application
 * `sys-stats` for the frontend [React](sys-stats/Dockerfile) application
 * `proxy` for the [Nginx](sys-stats/Dockerfile) proxy
 
 
A [docker-compose](docker-compose.yaml) exists to run the application. It has enabled auto reload for the React
application. Volumes have been defined to facilitate troubleshooting of local changes.

```shell script
docker compose up --build
```

To access the React application:

* Frontend: http://localhost:3050/
* Backend: http://localhost:3050/stats

Next, I will briefly describe the 3 components of this application.

## Backend

For the Docker container, I have chosen Debian slim base image, because fits well with python applications and has a
preconfigured `nobody` user to run applications as non-root. Application runs on port `8080`.

## Frontend

For the Docker container, I have chosen node alpine base image because it runs ok with Nginx. It is running on port
`3000`. Application is running with non-root user `node`.

I have introduced an environment variable `REACT_APP_BACKEND_SERVICE_URL` to pass the url for the backend python
application.

## Proxy

An Nginx container has been provided to [act](proxy/default.conf) as a proxy for the React application. Both backend and frontend applications
have been exposed through port `3050`:



# Task 2 Deploy on AWS with terraform
Task 2 adds logic to deploy the react application. This application is deployed in AWS using an ECS service. Two
services have been created for backend and frontend with configurable replicas and container definitions. A load
balancer has been configured to access the application using a DNS name provided by Amazon.


## Prerequisites and tools
I have used github actions defined in [workflows](.github/workflows) to create a reusable CICD pipeline to deploy
infrastructure and build Docker images using AWS cli and Terraform.

Github actions access to AWS is implemented using [OpenId Connect](https://docs.github.com/en/actions/deployment/security-hardening-your-deployments/configuring-openid-connect-in-amazon-web-services#prerequisites).
This configuration and [S3 terraform backend](https://developer.hashicorp.com/terraform/language/settings/backends/s3)
with DynamoDB state are already configured.

There are two github workflows configured:

* [terraform workflow](.github/workflows/terraform.yaml): This is a reusable github workflow configured to be called by
other workflows. It configures AWS and Terraform with inputs to specify terraform directory, version and variables and
make terraform outputs available to other workflows.
* [main](.github/workflows/main.yaml) workflow: This workflow main purpose is to deploy the application to ECS using
terraform. It contains several jobs to deploy infrastructure, build Docker images and test the exposed service url.

For simplicity, any pull request pointing to `main` branch will trigger an execution of the main pipeline. Note that
production systems may require different configurations.

## Approach and technical decisions
AWS ECS has been chosen as an example of orchestration environment to simulate a real scenario where teams create
containerised applications. Teams can create their applications using containers and push the images to a Container
Registry (AWS ECR in this case). Some infrastructure have been provisioned with the `apply-preconfigured-infrastructure`
job like a ECS cluster, IAM roles and ECR repositories, this can be found in the [preconfigured](tf/preconfigured)
directory. Credentials have been configured using AWS [profiles](credentials.aws)

A Terraform module has also been added to this repository called [app](tf/modules/app). In real environments this module
should be defined in other repositories and own by Infrastructure engineering teams. It has been added to provide an
example to run real infrastructure. This module configures an ECS service and task and the basic networking to expose
the service through a load balancer. I have added some basic configurations and much more can be done in real world
scenarios, but it is enough for this project.

As mentioned earlier, main github workflow will deploy the application to ECS. It does this work in several jobs: first
it deploys preconfigured infrastructure, then exposes ECR repositories urls, build Docker images and push them to ECR,
deploys applications to ECS using services and tasks and finally test whether the application is running.
Note that for production, more steps will be required like tests, secrets, security and environments.

An application deployed by a development team normally contains the logic, container image, pipelines and in some cases
the infrastructure it uses. This is the case for this exercise, the [main file](tf/main.tf) contains the Terraform
module invocation to configure the ECS service and Task. By default it defines a load balancer for each service, it is
out of the scope of this exercise to add logic to define more complex services. Inputs for the module have been defined
for different [environments](tf/environments).

# Task 3 - Get it to work with Kubernetes and fluxCD
For this task I have defined another Github [workflow](.github/workflows/flux.yaml). I have created a Kubernetes cluster
with 3 nodes using [Kind](https://kind.sigs.k8s.io/). I am not very familiar with Fluxcd, but I managed to create a
[HelmRelease](clusters/app.yaml) application using a self-host Husing a self-host Helm [chart](apps/stats)

This Helm chart defines a couple of deployments, service and ingress controller to expose the application to port 80.
I could have used `Kustomization` instead to reduce the complexity of handling templates, but I am not familiar with the
library. That would have helped me to configure the application to be ran on different environments. For simplicity, I
have not added configurations for several environments for this exercise.

