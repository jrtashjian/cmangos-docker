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

COPY InstallFullDB.diff /opt/src/database/InstallFullDB.diff
# Zero mtimes so separately built images produce identical layer digests.
RUN rm -rf /opt/src/database/.git \
	&& find /opt/src/database -exec touch -h -d @0 {} +

# --- runtime ---
ARG REGISTRY=registry.int.jrtashjian.com
FROM ${REGISTRY}/jrtashjian/cmangos-docker/runtime-base:latest

ARG CMANGOS_CORE
ENV CMANGOS_CORE=${CMANGOS_CORE}

LABEL org.opencontainers.image.title="mangosd-${CMANGOS_CORE}"
LABEL org.opencontainers.image.description="Containerized CMaNGOS Game Server"
LABEL org.opencontainers.image.authors="jrtashjian"
LABEL org.opencontainers.image.licenses="GPL-2.0-only"

COPY --from=builder /opt/src/database /opt/database
COPY --from=builder /opt/cmangos /opt/cmangos

COPY 00_init.sh /00_init.sh
RUN chmod +x /00_init.sh

VOLUME [ "/opt/cmangos/etc" ]

ENTRYPOINT ["/tini", "--"]
CMD ["/00_init.sh"]

EXPOSE 8085
