FROM buildpack-deps:stable as builder

ARG CMANGOS_CORE=classic

RUN DEBIAN_FRONTEND=noninteractive apt update && \
	DEBIAN_FRONTEND=noninteractive apt install -q -y \
		binutils \
		build-essential \
		cmake \
		grep \
		libboost-all-dev \
		libmariadb-dev \
		libmariadb-dev-compat \
		mariadb-server && \
	rm -rf /var/lib/apt/lists/*

RUN mkdir -p /opt/src && \
	git clone --depth 1 https://github.com/cmangos/mangos-${CMANGOS_CORE}.git /opt/src/cmangos

RUN mkdir -p /opt/src/cmangos/build && \
	cd /opt/src/cmangos/build && \
	cmake /opt/src/cmangos -DCMAKE_INSTALL_PREFIX=/opt/cmangos -DBUILD_GAME_SERVER=OFF -DBUILD_LOGIN_SERVER=OFF -DBUILD_EXTRACTORS=ON && \
	make -j $(nproc) && make install

RUN rm -rfv /opt/src

FROM debian:stable
LABEL org.opencontainers.image.source https://github.com/jrtashjian/cmangos-docker
LABEL org.opencontainers.image.authors jrtashjian
LABEL org.opencontainers.image.licenses GPL-2.0-only

COPY --from=builder /opt/cmangos /opt/cmangos
COPY extract.sh /extract.sh
RUN chmod +x /extract.sh \
	/opt/cmangos/bin/tools/ExtractResources.sh \
	/opt/cmangos/bin/tools/MoveMapGen.sh

CMD ["/extract.sh"]