ARG REGISTRY=registry.int.jrtashjian.com
FROM ${REGISTRY}/jrtashjian/cmangos-docker/builder-base:latest AS builder

ARG CMANGOS_CORE=classic
ARG CORE_COMMIT_HASH=HEAD
ARG DB_COMMIT_HASH=HEAD
ARG BUILD_PLAYERBOT=OFF
ARG BUILD_AHBOT=OFF
ARG BUILD_METRICS=OFF

RUN mkdir -p /opt/src && \
	git clone https://github.com/cmangos/mangos-${CMANGOS_CORE}.git /opt/src/cmangos && \
	if [ "$CORE_COMMIT_HASH" != "HEAD" ]; then cd /opt/src/cmangos; git checkout ${CORE_COMMIT_HASH}; fi

RUN mkdir -p /opt/src && \
	git clone https://github.com/cmangos/${CMANGOS_CORE}-db.git /opt/src/database && \
	if [ "$DB_COMMIT_HASH" != "HEAD" ]; then cd /opt/src/database; git checkout ${DB_COMMIT_HASH}; fi

RUN mkdir -p /opt/src/cmangos/build && \
	cd /opt/src/cmangos/build && \
	cmake /opt/src/cmangos -DCMAKE_INSTALL_PREFIX=/opt/cmangos -DBUILD_LOGIN_SERVER=OFF -DBUILD_PLAYERBOT=${BUILD_PLAYERBOT} -DBUILD_AHBOT=${BUILD_AHBOT} -DBUILD_METRICS=${BUILD_METRICS} && \
	make -j $(nproc) && make install

# Copy config and sql scripts
RUN cp -r /opt/cmangos/etc /opt/cmangos/configs
RUN mkdir -p /opt/cmangos/sql && \
	cp -r /opt/src/cmangos/sql /opt/cmangos

# Remove .git dir to minimize size
RUN rm -rfv /opt/src/database/.git

FROM bitnami/minideb:latest

ARG CMANGOS_CORE
ENV CMANGOS_CORE=${CMANGOS_CORE}

LABEL org.opencontainers.image.title="mangosd-${CMANGOS_CORE}"
LABEL org.opencontainers.image.description="Containerized CMaNGOS Game Server"
LABEL org.opencontainers.image.authors="jrtashjian"
LABEL org.opencontainers.image.licenses="GPL-2.0-only"

RUN apt update; \
	apt install -y \
		mariadb-client \
		libmariadb3 \
		wget \
		unzip \
	; rm -rf /var/lib/apt/lists/*

COPY --from=builder /opt/cmangos /opt/cmangos
COPY --from=builder /opt/src/database /opt/database
COPY InstallFullDB.diff /opt/database/InstallFullDB.diff

VOLUME [ "/opt/cmangos/etc" ]

# Copy over init scripts and make them executable
COPY 00_init.sh /00_init.sh
COPY wait-for-it.sh /wait-for-it.sh
RUN chmod +x /00_init.sh && chmod +x /wait-for-it.sh

# Add Tini
ENV TINI_VERSION=v0.19.0
ADD https://github.com/krallin/tini/releases/download/${TINI_VERSION}/tini /tini
RUN chmod +x /tini
ENTRYPOINT ["/tini", "--"]
CMD ["/00_init.sh"]

EXPOSE 8085