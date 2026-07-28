#!/bin/bash
set -euo pipefail

# Fetch CMaNGOS core (and optionally DB) sources once per variant for image builds.
# Usage: fetch-sources.sh <variant> [--core-hash HASH] [--db-hash HASH] [--with-db|--no-db]
#
# Clones into sources/<variant>/{cmangos,database} and reuses existing clones.

VARIANT="${1:-}"
if [ -z "$VARIANT" ] || [ "$VARIANT" = "-h" ] || [ "$VARIANT" = "--help" ]; then
	echo "Usage: $0 <classic|tbc|wotlk> [--core-hash HASH] [--db-hash HASH] [--with-db|--no-db]" >&2
	exit 1
fi
shift

CORE_HASH=HEAD
DB_HASH=HEAD
WITH_DB=1

while [ $# -gt 0 ]; do
	case "$1" in
		--core-hash)
			CORE_HASH="${2:?--core-hash requires a value}"
			shift 2
			;;
		--db-hash)
			DB_HASH="${2:?--db-hash requires a value}"
			shift 2
			;;
		--with-db)
			WITH_DB=1
			shift
			;;
		--no-db)
			WITH_DB=0
			shift
			;;
		*)
			echo "Unknown option: $1" >&2
			exit 1
			;;
	esac
done

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SOURCES_ROOT="${SOURCES_ROOT:-$SCRIPT_DIR/sources}"
CORE_URL="https://github.com/cmangos/mangos-${VARIANT}.git"
DB_URL="https://github.com/cmangos/${VARIANT}-db.git"

# Checkout ref into dest, reusing a shallow clone when possible.
# HEAD tracks origin's default branch tip.
checkout_ref() {
	local url=$1 dest=$2 ref=$3
	local fetch_ref

	if [ "$ref" = "HEAD" ]; then
		fetch_ref=HEAD
	else
		fetch_ref=$ref
	fi

	mkdir -p "$(dirname "$dest")"

	if [ -d "$dest/.git" ]; then
		git -C "$dest" remote set-url origin "$url"
	else
		rm -rf "$dest"
		mkdir -p "$dest"
		git -C "$dest" init -q
		git -C "$dest" remote add origin "$url"
	fi

	git -C "$dest" fetch --depth 1 --force origin "$fetch_ref"
	git -C "$dest" checkout --force --detach FETCH_HEAD
	# Keep named-context uploads lean; .git is only needed for the next fetch.
	printf '%s\n' '.git' >"$dest/.dockerignore"
}

echo "Fetching mangos-${VARIANT} @ ${CORE_HASH}"
checkout_ref "$CORE_URL" "$SOURCES_ROOT/$VARIANT/cmangos" "$CORE_HASH"

if [ "$WITH_DB" -eq 1 ]; then
	echo "Fetching ${VARIANT}-db @ ${DB_HASH}"
	checkout_ref "$DB_URL" "$SOURCES_ROOT/$VARIANT/database" "$DB_HASH"
fi

echo "Sources ready under $SOURCES_ROOT/$VARIANT"
