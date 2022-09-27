#!/bin/bash

variants=(classic tbc wotlk)
images=(extractors realmd mangosd)

for variant in "${variants[@]}"; do
	for image in "${images[@]}"; do
		docker build --no-cache -t "ghcr.io/jrtashjian/cmangos-docker/$image-$variant:master" ./$image --build-arg CMANGOS_CORE=$variant
		docker push "ghcr.io/jrtashjian/cmangos-docker/$image-$variant:master"
	done
done
