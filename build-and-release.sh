#!/bin/bash
set -euo pipefail

IMAGE_SOURCE="${IMAGE_SOURCE:-https://gitlab.int.jrtashjian.com/jrtashjian/cmangos-docker}"
REGISTRY="${REGISTRY:-registry.int.jrtashjian.com}"
DATE_TAG=$(date +%Y.%m.%d)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SOURCES_ROOT="${SOURCES_ROOT:-$SCRIPT_DIR/sources}"

CORE_COMMIT_HASH="${CORE_COMMIT_HASH:-HEAD}"
DB_COMMIT_HASH="${DB_COMMIT_HASH:-HEAD}"

variants=(wotlk)
images=(realmd extractors)
mangosd_types=(default) # ahbot playerbot ahbot-playerbot)

export DOCKER_BUILDKIT=1

# Shared runtime layers for realmd/mangosd (build once, reuse across variants)
runtime_image="${REGISTRY}/jrtashjian/cmangos-docker/runtime-base"
docker build ./runtime-base \
	--label "org.opencontainers.image.source=${IMAGE_SOURCE}" \
	-t "${runtime_image}:latest" \
	-t "${runtime_image}:${DATE_TAG}"
#docker push "${runtime_image}:latest"
#docker push "${runtime_image}:${DATE_TAG}"

for variant in "${variants[@]}"; do
	"$SCRIPT_DIR/fetch-sources.sh" "$variant" \
		--core-hash "$CORE_COMMIT_HASH" \
		--db-hash "$DB_COMMIT_HASH"

	source_args=(
		--build-context "cmangos=$SOURCES_ROOT/$variant/cmangos"
		--build-context "database=$SOURCES_ROOT/$variant/database"
	)
	build_args=(
		--build-arg "CMANGOS_CORE=$variant"
		--build-arg "REGISTRY=$REGISTRY"
		--label "org.opencontainers.image.source=${IMAGE_SOURCE}"
	)

	for image in "${images[@]}"; do
		image_name="${REGISTRY}/jrtashjian/cmangos-docker/$image-$variant"
		ctx_args=("${source_args[@]}")
		if [ "$image" = "extractors" ]; then
			ctx_args=(--build-context "cmangos=$SOURCES_ROOT/$variant/cmangos")
		fi

		docker build "./$image" "${ctx_args[@]}" "${build_args[@]}" \
			-t "${image_name}:latest" \
			-t "${image_name}:${DATE_TAG}"

		#docker push "${image_name}:latest"
		#docker push "${image_name}:${DATE_TAG}"
	done

	for type in "${mangosd_types[@]}"; do
		type_build_args=("${build_args[@]}")
		tag_extra=""

		case "$type" in
			playerbot)
				type_build_args+=(--build-arg BUILD_PLAYERBOT=ON)
				tag_extra="-playerbot"
				;;
			ahbot)
				type_build_args+=(--build-arg BUILD_AHBOT=ON)
				tag_extra="-ahbot"
				;;
			ahbot-playerbot)
				type_build_args+=(--build-arg BUILD_PLAYERBOT=ON --build-arg BUILD_AHBOT=ON)
				tag_extra="-ahbot-playerbot"
				;;
		esac

		image_name="${REGISTRY}/jrtashjian/cmangos-docker/mangosd-${variant}${tag_extra}"

		docker build ./mangosd "${source_args[@]}" "${type_build_args[@]}" \
			-t "${image_name}:latest" \
			-t "${image_name}:${DATE_TAG}"

		#docker push "${image_name}:latest"
		#docker push "${image_name}:${DATE_TAG}"
	done
done
