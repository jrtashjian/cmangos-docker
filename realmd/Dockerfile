# syntax=docker/dockerfile:1
ARG REGISTRY=registry.int.jrtashjian.com
FROM ${REGISTRY}/jrtashjian/cmangos-docker/builder-base:latest AS builder

ARG CMANGOS_CORE=classic

COPY --from=cmangos / /opt/src/cmangos
COPY --from=database / /opt/src/database

RUN mkdir -p /opt/src/cmangos/build && \
	cd /opt/src/cmangos/build && \
	cmake /opt/src/cmangos -DCMAKE_INSTALL_PREFIX=/opt/cmangos -DBUILD_GAME_SERVER=OFF && \
	make -j $(nproc) && make install

# Copy config and sql scripts
RUN cp -r /opt/cmangos/etc /opt/cmangos/configs
RUN mkdir -p /opt/cmangos/sql && \
	cp -r /opt/src/cmangos/sql /opt/cmangos

# Zero mtimes so separately built images produce identical layer digests.
RUN find /opt/src/database -exec touch -h -d @0 {} +

# --- runtime ---
ARG REGISTRY=registry.int.jrtashjian.com
FROM ${REGISTRY}/jrtashjian/cmangos-docker/runtime-base:latest

ARG CMANGOS_CORE
ENV CMANGOS_CORE=${CMANGOS_CORE}

LABEL org.opencontainers.image.title="realmd-${CMANGOS_CORE}"
LABEL org.opencontainers.image.description="Containerized CMaNGOS Login Server"
LABEL org.opencontainers.image.authors="jrtashjian"
LABEL org.opencontainers.image.licenses="GPL-2.0-only"

COPY --from=builder /opt/src/database /opt/database
COPY --from=builder /opt/cmangos /opt/cmangos

COPY 00_init.sh /00_init.sh
RUN chmod +x /00_init.sh

VOLUME [ "/opt/cmangos/etc" ]

ENTRYPOINT ["/00_init.sh"]

EXPOSE 3724
