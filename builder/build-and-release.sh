#!/bin/bash

docker build --no-cache -t "ghcr.io/jrtashjian/cmangos-docker/builder-base:latest" .
docker push "ghcr.io/jrtashjian/cmangos-docker/builder-base:latest"