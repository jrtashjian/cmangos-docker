#!/bin/bash
set -euo pipefail

IMAGE_SOURCE="${IMAGE_SOURCE:-https://github.com/jrtashjian/cmangos-docker}"
DATE_TAG=$(date +%Y.%m.%d)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SOURCES_ROOT="${SOURCES_ROOT:-$SCRIPT_DIR/sources}"

CORE_COMMIT_HASH="${CORE_COMMIT_HASH:-HEAD}"
DB_COMMIT_HASH="${DB_COMMIT_HASH:-HEAD}"

PUSH=0
for arg in "$@"; do
    case "$arg" in
    --push) PUSH=1 ;;
    -h | --help)
        echo "Usage: $0 [--push]"
        echo "  --push  Push built images to all registries (build only by default)"
        exit 0
        ;;
    *)
        echo "error: unknown argument: $arg" >&2
        echo "Usage: $0 [--push]" >&2
        exit 1
        ;;
    esac
done

# Registry path prefixes.
REGISTRIES=(${REGISTRIES:-registry.int.jrtashjian.com/jrtashjian/cmangos-docker ghcr.io/jrtashjian})
REGISTRY_HOST="${REGISTRIES[0]%%/*}"

variants=(classic) # classic tbc wotlk
images=(realmd extractors) # realmd extractors
mangosd_types=(ahbot-playerbot) # ahbot playerbot ahbot-playerbot

export DOCKER_BUILDKIT=1

# Full image reference for a registry prefix + logical image name + tag.
# GitLab keeps the bare name under the project path; all others get a cmangos- prefix.
image_ref() {
    local prefix="$1"
    local name="$2"
    local tag="$3"
    local host="${prefix%%/*}"

    case "$host" in
    registry.int.jrtashjian.com)
        echo "${prefix}/${name}:${tag}"
        ;;
    *)
        echo "${prefix}/cmangos-${name}:${tag}"
        ;;
    esac
}

# Append -t args for every registry × tag combination.
append_tags() {
    local image_name="$1"
    local -n _tags=$2
    local prefix
    for prefix in "${REGISTRIES[@]}"; do
        _tags+=(-t "$(image_ref "$prefix" "$image_name" latest)")
        _tags+=(-t "$(image_ref "$prefix" "$image_name" "$DATE_TAG")")
    done
}

# Push all registry tags for an image (no-op unless --push).
push_all() {
    local image_name="$1"
    local prefix tag

    if [ "$PUSH" -eq 0 ]; then
        return 0
    fi

    for prefix in "${REGISTRIES[@]}"; do
        for tag in latest "${DATE_TAG}"; do
            docker push "$(image_ref "$prefix" "$image_name" "$tag")"
        done
    done
}

echo "Registries: ${REGISTRIES[*]}"
echo "Date tag: ${DATE_TAG}"
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
    push_all "$base"
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
        --build-arg "REGISTRY=$REGISTRY_HOST"
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
        push_all "$image_name"
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
        push_all "$image_name"
    done
done
