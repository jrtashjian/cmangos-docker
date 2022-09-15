#!/bin/bash

docker build --no-cache -t "ghcr.io/jrtashjian/cmangos-builder:latest" ./builder
docker push "ghcr.io/jrtashjian/cmangos-builder:latest"

variants=(classic tbc wotlk)
images=(extractors realmd mangosd)

for variant in "${variants[@]}"; do
	for image in "${images[@]}"; do
		docker build --no-cache -t "ghcr.io/jrtashjian/cmangos-$image-$variant:latest" ./$image --build-arg CMANGOS_CORE=$variant
		docker push "ghcr.io/jrtashjian/cmangos-$image-$variant:latest"
	done
done
