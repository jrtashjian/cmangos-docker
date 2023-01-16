FROM buildpack-deps:stable
LABEL org.opencontainers.image.title builder-base
LABEL org.opencontainers.image.description Base image for building CMaNGOS
LABEL org.opencontainers.image.source https://github.com/jrtashjian/cmangos-docker/builder
LABEL org.opencontainers.image.authors jrtashjian
LABEL org.opencontainers.image.licenses GPL-2.0-only

RUN set -ex; \
	apt update; \
	apt full-upgrade -y; \
	apt install -y \
		binutils \
		build-essential \
		cmake \
		grep \
		libboost-all-dev \
		libmariadb-dev \
		libmariadb-dev-compat \
		mariadb-server \
	; \
	rm -rf /var/lib/apt/lists/*;