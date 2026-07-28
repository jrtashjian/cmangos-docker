# syntax=docker/dockerfile:1
ARG REGISTRY=registry.int.jrtashjian.com
FROM ${REGISTRY}/jrtashjian/cmangos-docker/builder-base:latest AS builder

ARG CMANGOS_CORE=classic

COPY --from=cmangos / /opt/src/cmangos

RUN mkdir -p /opt/src/cmangos/build && \
	cd /opt/src/cmangos/build && \
	cmake /opt/src/cmangos -DCMAKE_INSTALL_PREFIX=/opt/cmangos -DBUILD_GAME_SERVER=OFF -DBUILD_LOGIN_SERVER=OFF -DBUILD_EXTRACTORS=ON && \
	make -j $(nproc) && make install

RUN rm -rfv /opt/src

FROM bitnami/minideb:latest

ARG CMANGOS_CORE
ENV CMANGOS_CORE=${CMANGOS_CORE}

LABEL org.opencontainers.image.title="extractors-${CMANGOS_CORE}"
LABEL org.opencontainers.image.description="Containerized CMaNGOS Extractors"
LABEL org.opencontainers.image.authors="jrtashjian"
LABEL org.opencontainers.image.licenses="GPL-2.0-only"

COPY --from=builder --chown=cmangos:cmangos /opt/cmangos /opt/cmangos
COPY --chmod=755 --chown=cmangos:cmangos extract.sh /extract.sh

RUN groupadd -g 1000 cmangos && \
    useradd -u 1000 -g cmangos -M -s /usr/sbin/nologin cmangos && \
    chmod +x /opt/cmangos/bin/tools/ExtractResources.sh \
             /opt/cmangos/bin/tools/MoveMapGen.sh

USER cmangos

CMD ["/extract.sh"]
