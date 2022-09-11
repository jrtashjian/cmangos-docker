#!/bin/bash

VARIANTS=(classic tbc wotlk)

for variant in "${VARIANTS[@]}"
do
	echo "";
	echo "[BUILD] Extractors - $variant";
	echo "";
	docker build --no-cache -t "ghcr.io/jrtashjian/cmangos-extractors-$variant:latest" ./extractors --build-arg CMANGOS_CORE=$variant

	echo "";
	echo "[BUILD] RealmD - $variant";
	echo "";
	docker build --no-cache -t "ghcr.io/jrtashjian/cmangos-realmd-$variant:latest" ./realmd --build-arg CMANGOS_CORE=$variant

	echo "";
	echo "[BUILD] MangosD - $variant";
	echo "";
	docker build --no-cache -t "ghcr.io/jrtashjian/cmangos-mangosd-$variant:latest" ./mangosd --build-arg CMANGOS_CORE=$variant
done
