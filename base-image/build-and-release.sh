#!/bin/bash
IMAGE_SOURCE="${IMAGE_SOURCE:-https://gitlab.int.jrtashjian.com/jrtashjian/cmangos-docker}"

REGISTRY="${REGISTRY:-registry.int.jrtashjian.com}"
DATE_TAG=$(date +%Y.%m.%d)

docker build . --no-cache \
    --label "org.opencontainers.image.source=${IMAGE_SOURCE}" \
    -t "${REGISTRY}/jrtashjian/cmangos-docker/builder-base:latest" \
    -t "${REGISTRY}/jrtashjian/cmangos-docker/builder-base:${DATE_TAG}"

docker push "${REGISTRY}/jrtashjian/cmangos-docker/builder-base:latest"
docker push "${REGISTRY}/jrtashjian/cmangos-docker/builder-base:${DATE_TAG}"