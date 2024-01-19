#!/bin/bash
docker build -t "registry.int.jrtashjian.com/jrtashjian/cmangos-docker/base-image" .
docker push "registry.int.jrtashjian.com/jrtashjian/cmangos-docker/base-image"