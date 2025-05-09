FROM buildpack-deps:stable

ENV DEBIAN_FRONTEND=noninteractive

LABEL org.opencontainers.image.title="base-image"
LABEL org.opencontainers.image.description="Base image for building CMaNGOS"
LABEL org.opencontainers.image.authors="jrtashjian"
LABEL org.opencontainers.image.licenses="GPL-2.0-only"

RUN set -ex; \
	apt update && apt full-upgrade -y && apt install -y \
		binutils \
		build-essential \
		cmake \
		git-core \
		grep \
		libboost-all-dev \
		libmariadb-dev \
		libmariadb-dev-compat \
		mariadb-server \
	&& rm -rf /var/lib/apt/lists/*;