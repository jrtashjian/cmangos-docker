FROM ghcr.io/jrtashjian/cmangos-builder-base:latest as builder

ARG CMANGOS_CORE=classic
ARG CORE_COMMIT_HASH=HEAD

RUN mkdir -p /opt/src && \
	git clone https://github.com/cmangos/mangos-${CMANGOS_CORE}.git /opt/src/cmangos && \
	if [ "$CORE_COMMIT_HASH" != "HEAD" ]; then cd /opt/src/cmangos; git checkout ${CORE_COMMIT_HASH}; fi

RUN mkdir -p /opt/src/cmangos/build && \
	cd /opt/src/cmangos/build && \
	cmake /opt/src/cmangos -DCMAKE_INSTALL_PREFIX=/opt/cmangos -DBUILD_GAME_SERVER=OFF -DBUILD_LOGIN_SERVER=OFF -DBUILD_EXTRACTORS=ON && \
	make -j $(nproc) && make install

RUN rm -rfv /opt/src

FROM bitnami/minideb:latest
LABEL org.opencontainers.image.title extractors-${CMANGOS_CORE}
LABEL org.opencontainers.image.description Containerized CMaNGOS Extractors
LABEL org.opencontainers.image.source https://github.com/jrtashjian/cmangos-docker/extractors
LABEL org.opencontainers.image.authors jrtashjian
LABEL org.opencontainers.image.licenses GPL-2.0-only

COPY --from=builder /opt/cmangos /opt/cmangos
COPY extract.sh /extract.sh
RUN chmod +x /extract.sh \
	/opt/cmangos/bin/tools/ExtractResources.sh \
	/opt/cmangos/bin/tools/MoveMapGen.sh

CMD ["/extract.sh"]