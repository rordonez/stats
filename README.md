### Task 1 - Dockerize the Application

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

