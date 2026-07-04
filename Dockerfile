# Global build arguments — required values supplied via --build-arg by build.sh
# (sourced from versions/<ver>.env). Release-encoding args carry no defaults so a
# missing --build-arg fails loudly instead of silently building the wrong version.
ARG TZ="Etc/UTC"
ARG OMADA_USER="omada"
ARG OMADA_UID="550"
ARG OMADA_GID="550"
ARG OS_BASE
ARG MONGO_VER
ARG OMADA_VER
ARG OMADA_DOWNLOAD_URL
# Optional checksum for the Omada package.
# TP-Link does not publish official checksums, so this value is maintained manually.
# Set to empty to skip verification.
ARG OMADA_SHA512
ARG JAVA_VER
ARG JAVA_HOME="/usr/lib/jvm/java-${JAVA_VER}-openjdk-amd64"
ARG JAVA_PKG="openjdk-${JAVA_VER}-jdk-headless"

# Stage 1: Build and install jsvc from source
FROM ${OS_BASE} AS build-jsvc
  # Re-declare global args and add build-specific args
  ARG TZ
  ARG JAVA_HOME
  ARG JAVA_PKG
  ARG JSVC_VER
  ENV TZ=${TZ} DEBIAN_FRONTEND="noninteractive"
  ARG JSVC_BASE_URL="https://archive.apache.org/dist/commons/daemon/source"  # Archive URL for older versions
  # ARG JSVC_BASE_URL="https://dlcdn.apache.org/commons/daemon/source" # Newer URL for latest versions
  ARG JSVC_ARCHIVE="commons-daemon-${JSVC_VER}-src.tar.gz"

  RUN apt-get -yq update && \
      apt-get -yq install apt-utils curl ${JAVA_PKG} libcap-dev autoconf make gcc

  RUN set -e; \
    echo "==> Downloading and building jsvc ${JSVC_VER}" && \
    curl -fsSL -O "${JSVC_BASE_URL}/${JSVC_ARCHIVE}" && \
    curl -fsSL -O "${JSVC_BASE_URL}/${JSVC_ARCHIVE}.sha512" && \
    # Verify checksum
    sha512sum -c "${JSVC_ARCHIVE}.sha512" && \
    tar xzf "${JSVC_ARCHIVE}" && \
    cd "commons-daemon-${JSVC_VER}-src/src/native/unix/" && \
    export CFLAGS="-m64" LDFLAGS="-m64" && \
    sh support/buildconf.sh && \
    ./configure --with-java="${JAVA_HOME}" && \
    make && \
    cp jsvc /usr/bin/jsvc && \
    # Cleanup
    cd / && \
    rm -rf "commons-daemon-${JSVC_VER}-src" "commons-daemon-${JSVC_VER}-src.tar.gz"*

# Stage 2: Final
FROM ${OS_BASE} AS final-stage
# Re-declare global args
ARG TZ
ARG OS_BASE
ARG MONGO_VER
ARG OMADA_VER
ARG OMADA_DOWNLOAD_URL
ARG OMADA_SHA512
ARG OMADA_USER
ARG OMADA_UID
ARG OMADA_GID
ARG JAVA_HOME
ARG JAVA_PKG

ENV TZ=${TZ} DEBIAN_FRONTEND="noninteractive"
ENV OMADA_USER=${OMADA_USER}

SHELL ["/bin/bash", "-eo", "pipefail", "-c"]

LABEL org.opencontainers.image.title="omada-controller"\
 org.opencontainers.image.description="Container image for TP-Link Omada Software Controller"\
 org.opencontainers.image.base.name="docker.io/library/${OS_BASE}"\
 org.opencontainers.image.version="${OMADA_VER}"

WORKDIR /omada
COPY --chmod=555 healthcheck.sh entrypoint.sh omada_sudoers ./
COPY --from=build-jsvc --chmod=555 /usr/bin/jsvc /usr/bin/

# Add repositories, update system and install prerequisites
RUN apt-get -yq update && \
  echo "==> Installing prerequisites and MongoDB ${MONGO_VER}" && \
  apt-get -yq --no-install-recommends install apt-utils curl gnupg sudo ${JAVA_PKG} libcap2 && \
  curl -fsSL https://www.mongodb.org/static/pgp/server-8.0.asc | gpg -o /usr/share/keyrings/mongodb-server-8.0.gpg --dearmor && \
  echo "deb [ arch=amd64,arm64 signed-by=/usr/share/keyrings/mongodb-server-8.0.gpg ] https://repo.mongodb.org/apt/ubuntu noble/mongodb-org/8.0 multiverse" | tee /etc/apt/sources.list.d/mongodb-org-8.0.list && \
  apt-get -q update && \
  apt-get --no-install-recommends -yq install \
   mongodb-org=${MONGO_VER} \
   mongodb-org-database=${MONGO_VER} \
   mongodb-org-server=${MONGO_VER} \
   mongodb-mongosh \
   mongodb-org-shell=${MONGO_VER} \
   mongodb-org-mongos=${MONGO_VER} \
   mongodb-org-tools=${MONGO_VER} \
   mongodb-org-database-tools-extra=${MONGO_VER} && \
  apt-get -yq clean && apt-get -yq autoremove && rm -rf /var/lib/apt/lists/*

# Install and configure Omada-Controller software
ENV JAVA_HOME=${JAVA_HOME}
RUN echo "==> Creating omada user and group" && \
  groupadd -g "${OMADA_GID}" "${OMADA_USER}" && \
  useradd -l -u "${OMADA_UID}" -g "${OMADA_GID}" -d /opt/tplink/EAPController/data -s /usr/sbin/nologin -M "${OMADA_USER}" && \
  echo "==> Installing sudoers file" && \
  chmod 0440 omada_sudoers && mv omada_sudoers /etc/sudoers.d && \
  echo "==> Downloading Omada package" && \
  curl -fsSLO "${OMADA_DOWNLOAD_URL}" && \
  OMADA_FILE="$(basename "${OMADA_DOWNLOAD_URL}")" && \
  if [ -n "${OMADA_SHA512}" ]; then echo "${OMADA_SHA512}  ./${OMADA_FILE}" | sha512sum -c -; else echo "Warning: OMADA_SHA512 is not set; skipping package checksum verification"; fi && \
  echo "==> Extracting and installing Omada package" && \
  OMADA_DIR="${OMADA_FILE%_*.tar.gz}" && \
  ls -l "./${OMADA_FILE}" && sha512sum "./${OMADA_FILE}" && \
  tar xzfp "./${OMADA_FILE}" && \
  # dpkg -i --ignore-depends=jsvc,java17-runtime,java17-runtime-headless,jdk-17 ./${OMADA_FILE} && \
  echo "==> Installing Omada in cluster mode" && \
  (cd "${OMADA_DIR}" && echo "y" | bash ./install.sh init-cluster-mode) && \
  echo "==> Creating writable directories and setting permissions" && \
  mkdir -p /opt/tplink/EAPController/logs /opt/tplink/EAPController/data /opt/tplink/EAPController/work && \
  chown -R "${OMADA_UID}:${OMADA_GID}" /opt/tplink/EAPController/logs /opt/tplink/EAPController/data /opt/tplink/EAPController/work /opt/tplink/EAPController/properties && \
  echo "==> Cleaning up" && \
  rm -fr "${OMADA_DIR}" && rm -f "${OMADA_FILE}"

EXPOSE 8088 8043 8843 19810/udp 27001/udp 29810/udp 29811 29812 29813 29814 29815 29816 29817

VOLUME [ "/opt/tplink/EAPController/logs", "/opt/tplink/EAPController/data" ]

USER ${OMADA_USER}

ENTRYPOINT ["/omada/entrypoint.sh"]

HEALTHCHECK --interval=3m --timeout=30s --start-period=4m --retries=2 \
  CMD ["/omada/healthcheck.sh"]
