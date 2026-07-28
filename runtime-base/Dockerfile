FROM bitnami/minideb:latest

LABEL org.opencontainers.image.title="runtime-base"
LABEL org.opencontainers.image.description="Shared runtime base for CMaNGOS server images"
LABEL org.opencontainers.image.authors="jrtashjian"
LABEL org.opencontainers.image.licenses="GPL-2.0-only"

RUN install_packages ca-certificates mariadb-client libmariadb3 python3

COPY --chmod=755 wait-for-it.sh /wait-for-it.sh
COPY --chmod=755 srp6_verifier.py /usr/share/cmangos/srp6_verifier.py
COPY --chmod=755 check-port /usr/local/bin/check-port
COPY InstallFullDB.diff /usr/share/cmangos/InstallFullDB.diff
COPY init-lib.sh /usr/share/cmangos/init-lib.sh

RUN groupadd -g 1000 cmangos && \
    useradd -u 1000 -g cmangos -M -s /usr/sbin/nologin cmangos

USER cmangos
