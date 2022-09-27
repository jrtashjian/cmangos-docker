FROM ghcr.io/jrtashjian/cmangos-docker/builder-base:latest as builder

ARG CMANGOS_CORE=classic

RUN mkdir -p /opt/src && \
	git clone --depth 1 https://github.com/cmangos/mangos-${CMANGOS_CORE}.git /opt/src/cmangos

RUN mkdir -p /opt/src/cmangos/build && \
	cd /opt/src/cmangos/build && \
	cmake /opt/src/cmangos -DCMAKE_INSTALL_PREFIX=/opt/cmangos -DBUILD_GAME_SERVER=OFF && \
	make -j $(nproc) && make install

# Copy config and sql scripts
RUN cp -r /opt/cmangos/etc /opt/cmangos/configs
RUN mkdir -p /opt/cmangos/sql && cp /opt/src/cmangos/sql/base/realmd.sql /opt/cmangos/sql/

RUN rm -rfv /opt/src

FROM bitnami/minideb:latest
LABEL org.opencontainers.image.title realmd-${CMANGOS_CORE}
LABEL org.opencontainers.image.description Containerized CMaNGOS Login Server
LABEL org.opencontainers.image.source https://github.com/jrtashjian/cmangos-docker/realmd
LABEL org.opencontainers.image.authors jrtashjian
LABEL org.opencontainers.image.licenses GPL-2.0-only

ARG CMANGOS_CORE
ENV CMANGOS_CORE=$CMANGOS_CORE

RUN apt update; \
	apt install -y \
		mariadb-client \
		libmariadb3 \
		wget \
		unzip \
	; \
	rm -rf /var/lib/apt/lists/*

COPY --from=builder /opt/cmangos /opt/cmangos

VOLUME [ "/opt/cmangos/etc" ]

# Copy over init scripts and make them executable
COPY 00_init.sh /00_init.sh
COPY wait-for-it.sh /wait-for-it.sh
RUN chmod +x /00_init.sh && chmod +x /wait-for-it.sh

# Add Tini
ENV TINI_VERSION v0.19.0
ADD https://github.com/krallin/tini/releases/download/${TINI_VERSION}/tini /tini
RUN chmod +x /tini
ENTRYPOINT ["/tini", "--"]
CMD ["/00_init.sh"]

EXPOSE 3724