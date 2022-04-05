#!/bin/bash

RUNNING_TAG=$(docker ps --filter name=magmad --format "{{.Image}}" | cut -d ":" -f 2)

source /var/opt/magma/docker/.env

# If tag running is equal to .env, then do nothing
if [ "$RUNNING_TAG" == "$IMAGE_VERSION" ]; then
  exit
fi

if pidof -o %PPID -x $0 >/dev/null; then
  echo "Upgrade process already running"
  exit
fi

# Otherwise recreate containers with the new image
cd /var/opt/magma/docker || exit

# Validate docker-compose file
CONFIG=$(docker-compose -f docker-compose.yaml config)
if [ -z "$CONFIG" ]; then
  echo "docker-compose.yml is not valid"
  exit
fi

# Pull all images
/usr/local/bin/docker-compose pull

CONTAINERS=$(docker ps -a -q)
[[ -z "$CONTAINERS" ]] || docker stop "$CONTAINERS"

# Bring containers up
/usr/local/bin/docker-compose up -d

# Remove all stopped containers and dangling images
docker system prune -af
