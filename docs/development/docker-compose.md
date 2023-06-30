# Docker compose

Only for testing of docker image and container locally.

This has been added so we can test the Dockerfile build. It can also be used
to run the app locally in manner similar to hosted environment to help with debugging
any asset or dependency issues.

## Prerequisites

- [Docker desktop for mac](https://docs.docker.com/desktop/install/mac-install/) (Docker version 20.10.21)

## Build and run

```shell
docker compose build
docker compose up # -d to daemonize
open http://0.0.0.0:3000

# to stop undaemonized version
Ctrl+c

# to stop daemonized version
docker compose stop
```

```shell
# to display all output, including any RUN shell command output, and not use cached layers
docker-compose build --progress=plain --no-cache
```

### Clean up (for a fresh start)

Stop containers first

```shell
# WARNING: removes all stopped containers and images
docker system prune -a

# list [persisted] volumes, such as databases, and remove
docker volume ls
docker volume rm <my-volume-name1> <my-volume-name2>
docker volume rm laa-assure-hmrc-data-db laa-assure-hmrc-data-gem_cache laa-assure-hmrc-data-node_modules
```

### Tail logs

```shell
# docker-compose logs -f <service-name>
#.e.g.
docker compose logs -f web
docker compose logs -f database
```

OR

```shell
# shell in and tail logs
docker compose exec web sh
tail -f log/production.log
```

### Shell into running web container

```shell
docker compose exec web sh
docker compose exec database sh
```
