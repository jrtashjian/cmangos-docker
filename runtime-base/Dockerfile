FROM bitnami/minideb:latest

LABEL org.opencontainers.image.title="runtime-base"
LABEL org.opencontainers.image.description="Shared runtime base for CMaNGOS server images"
LABEL org.opencontainers.image.authors="jrtashjian"
LABEL org.opencontainers.image.licenses="GPL-2.0-only"

RUN apt update; \
	apt install -y \
		mariadb-client \
		libmariadb3 \
		wget \
		unzip \
	; rm -rf /var/lib/apt/lists/*

COPY wait-for-it.sh /wait-for-it.sh
COPY check-port /usr/local/bin/check-port
COPY InstallFullDB.diff /usr/share/cmangos/InstallFullDB.diff
COPY init-lib.sh /usr/share/cmangos/init-lib.sh
RUN chmod +x /wait-for-it.sh /usr/local/bin/check-port
