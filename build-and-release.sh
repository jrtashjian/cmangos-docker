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

variants=(classic tbc wotlk) # classic tbc wotlk
images=(realmd extractors) # realmd extractors
mangosd_types=(default ahbot playerbot ahbot-playerbot) # default ahbot playerbot ahbot-playerbot

export DOCKER_BUILDKIT=1

# Full image reference: REGISTRY / printf(IMAGE_FORMAT, name) : tag
image_ref() {
	local name="$1"
	local tag="$2"
	printf '%s/%s:%s\n' "$REGISTRY" "$(printf "$IMAGE_FORMAT" "$name")" "$tag"
}

# Append -t args for each tag.
append_tags() {
	local image_name="$1"
	local -n _tags=$2
	shift 2
	local tag
	for tag in "$@"; do
		_tags+=(-t "$(image_ref "$image_name" "$tag")")
	done
}

# Push the given tags for an image (no-op unless --push).
push_image() {
	local image_name="$1"
	shift
	local tag

	if [ "$PUSH" -eq 0 ]; then
		return 0
	fi

	for tag in "$@"; do
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
	image_tags=(latest "$DATE_TAG")
	append_tags "$base" tags "${image_tags[@]}"
	docker build "./$base" \
		--label "org.opencontainers.image.source=${IMAGE_SOURCE}" \
		"${tags[@]}"
	push_image "$base" "${image_tags[@]}"
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
		image_tags=(latest "$DATE_TAG")
		append_tags "$image_name" tags "${image_tags[@]}"
		docker build "./$image" "${ctx_args[@]}" "${build_args[@]}" "${tags[@]}"
		push_image "$image_name" "${image_tags[@]}"
	done

	# mangosd: one image name per core; feature set is encoded in tags.
	#   default:           latest, 2026.08.05
	#   ahbot:             with-ahbot, 2026.08.05-with-ahbot
	#   playerbot:         with-playerbot, 2026.08.05-with-playerbot
	#   ahbot-playerbot:   with-playerbot-ahbot, 2026.08.05-with-playerbot-ahbot
	image_name="mangosd-${variant}"
	for type in "${mangosd_types[@]}"; do
		type_build_args=("${build_args[@]}")
		image_tags=()

		case "$type" in
		default)
			image_tags=(latest "$DATE_TAG")
			;;
		playerbot)
			type_build_args+=(--build-arg BUILD_PLAYERBOTS=ON)
			image_tags=(with-playerbot "${DATE_TAG}-with-playerbot")
			;;
		ahbot)
			type_build_args+=(--build-arg BUILD_AHBOT=ON)
			image_tags=(with-ahbot "${DATE_TAG}-with-ahbot")
			;;
		ahbot-playerbot)
			type_build_args+=(--build-arg BUILD_PLAYERBOTS=ON --build-arg BUILD_AHBOT=ON)
			image_tags=(with-playerbot-ahbot "${DATE_TAG}-with-playerbot-ahbot")
			;;
		*)
			echo "error: unknown mangosd type: $type" >&2
			exit 1
			;;
		esac

		tags=()
		append_tags "$image_name" tags "${image_tags[@]}"
		docker build ./mangosd "${source_args[@]}" "${type_build_args[@]}" "${tags[@]}"
		push_image "$image_name" "${image_tags[@]}"
	done
done
