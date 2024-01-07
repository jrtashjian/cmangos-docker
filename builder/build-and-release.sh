#!/bin/bash

docker build -t "registry.int.jrtashjian.com/jrtashjian/cmangos-docker/builder-base" .
docker push "registry.int.jrtashjian.com/jrtashjian/cmangos-docker/builder-base"