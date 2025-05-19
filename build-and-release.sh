#!/bin/bash
IMAGE_SOURCE="${IMAGE_SOURCE:-https://gitlab.int.jrtashjian.com/jrtashjian/cmangos-docker}"

REGISTRY="${REGISTRY:-registry.int.jrtashjian.com}"
DATE_TAG=$(date +%Y.%m.%d)

variants=(classic)
images=(realmd extractors)
mangosd_types=(default ahbot playerbot ahbot-playerbot)

for variant in "${variants[@]}"; do
	build_args=(--build-arg CMANGOS_CORE="$variant" --build-arg REGISTRY="$REGISTRY" --label "org.opencontainers.image.source=${IMAGE_SOURCE}")

	for image in "${images[@]}"; do
		image_name="${REGISTRY}/jrtashjian/cmangos-docker/$image-$variant"

		docker build ./$image --no-cache "${build_args[@]}" \
			-t "${image_name}:latest" \
			-t "${image_name}:${DATE_TAG}"

		docker push "${image_name}:latest"
		docker push "${image_name}:${DATE_TAG}"
	done

	for type in "${mangosd_types[@]}"; do
		tag_extra=""

		case "$type" in
			playerbot)
				build_args+=(--build-arg BUILD_PLAYERBOT=ON)
				tag_extra="-playerbot"
				;;
			ahbot)
				build_args+=(--build-arg BUILD_AHBOT=ON)
				tag_extra="-ahbot"
				;;
			ahbot-playerbot)
				build_args+=(--build-arg BUILD_PLAYERBOT=ON --build-arg BUILD_AHBOT=ON)
				tag_extra="-ahbot-playerbot"
				;;
		esac

		image_name="${REGISTRY}/jrtashjian/cmangos-docker/mangosd-${variant}${tag_extra}"

		docker build ./mangosd --no-cache "${build_args[@]}" \
			-t "${image_name}:latest" \
			-t "${image_name}:${DATE_TAG}"

		docker push "${image_name}:latest"
		docker push "${image_name}:${DATE_TAG}"
	done
done