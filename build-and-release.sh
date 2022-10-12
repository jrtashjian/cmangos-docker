#!/bin/bash

variants=(classic tbc wotlk)
images=(extractors realmd)

for variant in "${variants[@]}"; do
	for image in "${images[@]}"; do
		docker build --no-cache -t "ghcr.io/jrtashjian/cmangos-$image-$variant:latest" ./$image --build-arg CMANGOS_CORE=$variant
		docker push "ghcr.io/jrtashjian/cmangos-$image-$variant:latest"
	done
done

for variant in "${variants[@]}"; do
	docker build --no-cache -t "ghcr.io/jrtashjian/cmangos-mangosd-$variant:latest" ./mangosd --build-arg CMANGOS_CORE=$variant
	docker push "ghcr.io/jrtashjian/cmangos-mangosd-$variant:latest"

	docker build --no-cache -t "ghcr.io/jrtashjian/cmangos-mangosd-$variant:playerbot" ./mangosd --build-arg CMANGOS_CORE=$variant --build-arg BUILD_PLAYERBOT=ON
	docker push "ghcr.io/jrtashjian/cmangos-mangosd-$variant:playerbot"

	docker build --no-cache -t "ghcr.io/jrtashjian/cmangos-mangosd-$variant:ahbot" ./mangosd --build-arg CMANGOS_CORE=$variant --build-arg BUILD_AHBOT=ON
	docker push "ghcr.io/jrtashjian/cmangos-mangosd-$variant:ahbot"

	docker build --no-cache -t "ghcr.io/jrtashjian/cmangos-mangosd-$variant:playerbot-ahbot" ./mangosd --build-arg CMANGOS_CORE=$variant --build-arg BUILD_PLAYERBOT=ON --build-arg BUILD_AHBOT=ON
	docker push "ghcr.io/jrtashjian/cmangos-mangosd-$variant:playerbot-ahbot"
done