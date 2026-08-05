#!/bin/bash
set -euo pipefail

IMAGE_SOURCE="${IMAGE_SOURCE:-https://github.com/jrtashjian/cmangos-docker}"
DATE_TAG=$(date +%Y.%m.%d)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SOURCES_ROOT="${SOURCES_ROOT:-$SCRIPT_DIR/sources}"

CORE_COMMIT_HASH="${CORE_COMMIT_HASH:-HEAD}"
DB_COMMIT_HASH="${DB_COMMIT_HASH:-HEAD}"

# Single registry namespace prefix and printf format for the image name (%s = logical name).
# GitHub:  REGISTRY=ghcr.io/jrtashjian IMAGE_FORMAT='cmangos-%s'
# GitLab:  REGISTRY=registry.int.jrtashjian.com/jrtashjian/cmangos-docker IMAGE_FORMAT='%s'
REGISTRY="${REGISTRY:-ghcr.io/jrtashjian}"
IMAGE_FORMAT="${IMAGE_FORMAT:-cmangos-%s}"

PUSH=0
for arg in "$@"; do
	case "$arg" in
	--push) PUSH=1 ;;
	-h | --help)
		echo "Usage: REGISTRY=<prefix> IMAGE_FORMAT=<printf> $0 [--push]"
		echo
		echo "  REGISTRY       Registry namespace prefix (default: ghcr.io/jrtashjian)"
		echo "  IMAGE_FORMAT   printf format for image name; %s = logical name"
		echo "                 (default: cmangos-%s)"
		echo "  --push         Push built images (build only by default)"
		echo
		echo "Examples:"
		echo "  # GitHub Container Registry"
		echo "  REGISTRY=ghcr.io/jrtashjian IMAGE_FORMAT='cmangos-%s' $0 --push"
		echo
		echo "  # GitLab Container Registry"
		echo "  REGISTRY=registry.int.jrtashjian.com/jrtashjian/cmangos-docker IMAGE_FORMAT='%s' $0 --push"
		exit 0
		;;
	*)
		echo "error: unknown argument: $arg" >&2
		echo "Usage: REGISTRY=<prefix> IMAGE_FORMAT=<printf> $0 [--push]" >&2
		exit 1
		;;
	esac
done

variants=(classic) # classic tbc wotlk
images=(realmd extractors) # realmd extractors
mangosd_types=(default) # ahbot playerbot ahbot-playerbot

export DOCKER_BUILDKIT=1

# Full image reference: REGISTRY / printf(IMAGE_FORMAT, name) : tag
image_ref() {
	local name="$1"
	local tag="$2"
	printf '%s/%s:%s\n' "$REGISTRY" "$(printf "$IMAGE_FORMAT" "$name")" "$tag"
}

# Append -t args for latest and date tags.
append_tags() {
	local image_name="$1"
	local -n _tags=$2
	_tags+=(-t "$(image_ref "$image_name" latest)")
	_tags+=(-t "$(image_ref "$image_name" "$DATE_TAG")")
}

# Push tags for an image (no-op unless --push).
push_image() {
	local image_name="$1"
	local tag

	if [ "$PUSH" -eq 0 ]; then
		return 0
	fi

	for tag in latest "${DATE_TAG}"; do
		docker push "$(image_ref "$image_name" "$tag")"
	done
}

BUILDER_BASE="$(image_ref builder-base latest)"
RUNTIME_BASE="$(image_ref runtime-base latest)"

echo "Registry: ${REGISTRY}"
echo "Image format: ${IMAGE_FORMAT}"
echo "Date tag: ${DATE_TAG}"
echo "Builder base: ${BUILDER_BASE}"
echo "Runtime base: ${RUNTIME_BASE}"
if [ "$PUSH" -eq 1 ]; then
	echo "Push: enabled"
else
	echo "Push: disabled (pass --push to publish)"
fi

# Shared base images (build once, reuse across variants)
for base in builder-base runtime-base; do
	tags=()
	append_tags "$base" tags
	docker build "./$base" \
		--label "org.opencontainers.image.source=${IMAGE_SOURCE}" \
		"${tags[@]}"
	push_image "$base"
done

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
		--build-arg "BUILDER_BASE=$BUILDER_BASE"
		--build-arg "RUNTIME_BASE=$RUNTIME_BASE"
		--label "org.opencontainers.image.source=${IMAGE_SOURCE}"
	)

	for image in "${images[@]}"; do
		image_name="${image}-${variant}"
		ctx_args=("${source_args[@]}")
		if [ "$image" = "extractors" ]; then
			ctx_args=(--build-context "cmangos=$SOURCES_ROOT/$variant/cmangos")
		fi

		tags=()
		append_tags "$image_name" tags
		docker build "./$image" "${ctx_args[@]}" "${build_args[@]}" "${tags[@]}"
		push_image "$image_name"
	done

	for type in "${mangosd_types[@]}"; do
		type_build_args=("${build_args[@]}")
		tag_extra=""

		case "$type" in
		playerbot)
			type_build_args+=(--build-arg BUILD_PLAYERBOTS=ON)
			tag_extra="-playerbot"
			;;
		ahbot)
			type_build_args+=(--build-arg BUILD_AHBOT=ON)
			tag_extra="-ahbot"
			;;
		ahbot-playerbot)
			type_build_args+=(--build-arg BUILD_PLAYERBOTS=ON --build-arg BUILD_AHBOT=ON)
			tag_extra="-ahbot-playerbot"
			;;
		esac

		image_name="mangosd-${variant}${tag_extra}"
		tags=()
		append_tags "$image_name" tags
		docker build ./mangosd "${source_args[@]}" "${type_build_args[@]}" "${tags[@]}"
		push_image "$image_name"
	done
done
