# Global Arguments
ARG TZ="Etc/UTC"
ARG OS_BASE="ubuntu:24.04"
ARG MONGO_VER="8.0.15"
ARG OMADA_VER="6.0.0.24"
ARG OMADA_DOWNLOAD_URL="https://static.tp-link.com/upload/software/2025/202510/20251031/Omada_SDN_Controller_v6.0.0.24_linux_x64_20251027202524.tar.gz"
ARG OMADA_USER="omada"
ARG OMADA_UID="550"
ARG OMADA_GID="550"
ARG JAVA_HOME="/usr/lib/jvm/java-25-openjdk-amd64"
ARG JAVA_PKG="openjdk-25-jdk-headless" 

# Stage 1: Build the jsvc binary
FROM ${OS_BASE} AS build-stage
  # Re-declare global args
  ARG TZ
  ARG JAVA_HOME
  ARG JAVA_PKG
  ENV TZ=${TZ} DEBIAN_FRONTEND="noninteractive" 

  RUN apt-get -yq update && \
      apt-get -yq install apt-utils curl ${JAVA_PKG} libcap-dev autoconf make gcc

  RUN curl -fsSL -O https://dlcdn.apache.org/commons/daemon/source/commons-daemon-1.4.1-src.tar.gz && \
      curl -fsSL -O https://downloads.apache.org/commons/daemon/source/commons-daemon-1.4.1-src.tar.gz.sha512 && \
      sha512sum -c commons-daemon-1.4.1-src.tar.gz.sha512 && \
      tar xvzf commons-daemon-1.4.1-src.tar.gz && \
      cd commons-daemon-1.4.1-src/src/native/unix/ && \
      export CFLAGS="-m64" LDFLAGS="-m64" && \
      sh support/buildconf.sh && \
      ./configure --with-java=${JAVA_HOME} && \ 
      make && \
      mv jsvc /usr/bin/

# Stage 2: Final
FROM ${OS_BASE} AS final-stage
# Re-declare global args
ARG TZ
ARG OS_BASE
ARG MONGO_VER
ARG OMADA_VER
ARG OMADA_DOWNLOAD_URL
ARG OMADA_USER
ARG OMADA_UID
ARG OMADA_GID
ARG JAVA_HOME
ARG JAVA_PKG

ENV TZ=${TZ} DEBIAN_FRONTEND="noninteractive"
ENV OMADA_USER=${OMADA_USER}

LABEL org.opencontainers.image.title="omada-controller"\
 org.opencontainers.image.description="TP-Link Omada Software Controller"\
 org.opencontainers.image.base.name="docker.io/library/${OS_BASE}"\
 org.opencontainers.image.version="${OMADA_VER}"

WORKDIR /omada
COPY entrypoint.sh omada_sudoers $WORKDIR
COPY --from=build-stage --chmod=555 /usr/bin/jsvc /usr/bin/

# Add repositories, update system and install prerequisites
RUN apt-get -yq update && \  
  apt-get -yq --no-install-recommends install apt-utils curl gnupg sudo ${JAVA_PKG} libcap2 && \
  curl -fsSL https://www.mongodb.org/static/pgp/server-8.0.asc | sudo gpg -o /usr/share/keyrings/mongodb-server-8.0.gpg --dearmor && \
  echo "deb [ arch=amd64,arm64 signed-by=/usr/share/keyrings/mongodb-server-8.0.gpg ] https://repo.mongodb.org/apt/ubuntu noble/mongodb-org/8.0 multiverse" | sudo tee /etc/apt/sources.list.d/mongodb-org-8.0.list && \
  apt-get -q update && \
  sudo apt-get --no-install-recommends -yq install \
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
RUN groupadd -g ${OMADA_GID} ${OMADA_USER} && useradd -u ${OMADA_UID} -g ${OMADA_GID} -d /opt/tplink/EAPController/data -s /usr/sbin/nologin -M ${OMADA_USER} && \
  chmod 0440 omada_sudoers && mv omada_sudoers /etc/sudoers.d && \
  curl -fsSLO ${OMADA_DOWNLOAD_URL} && \
  OMADA_FILE="$(basename ${OMADA_DOWNLOAD_URL})" && \
  OMADA_DIR="${OMADA_FILE%_*.tar.gz}" && \
  ls -l ./${OMADA_FILE} && sha512sum ./${OMADA_FILE} && \
  tar xzvfp ./${OMADA_FILE} && \
  # dpkg -i --ignore-depends=jsvc,java17-runtime,java17-runtime-headless,jdk-17 ./${OMADA_FILE} && \
  (cd ${OMADA_DIR} && echo "y" | bash ./install.sh init-cluster-mode) && \
  mkdir -p /opt/tplink/EAPController/logs /opt/tplink/EAPController/data /opt/tplink/EAPController/work && \
  chown -R ${OMADA_UID}:${OMADA_GID} /opt/tplink/EAPController/logs /opt/tplink/EAPController/data /opt/tplink/EAPController/work /opt/tplink/EAPController/properties && \
  rm -fr ${OMADA_DIR} && rm -f ${OMADA_FILE}
  # cat /opt/tplink/EAPController/logs/startup.log && \
  # tpeap stop && rm -f ./${OMADA_FILE} && \

EXPOSE 8088 8043 8843 19810/udp 27001/udp 29810/udp 29811 29812 29813 29814 29815 29816 29817

VOLUME [ "/opt/tplink/EAPController/logs", "/opt/tplink/EAPController/data" ]

USER ${OMADA_USER}

ENTRYPOINT ["/omada/entrypoint.sh"]

HEALTHCHECK --interval=5m --timeout=30s --start-period=2m --retries=2 \
 CMD sudo /usr/bin/tpeap status | cut -c -28 | xargs -I % test "Omada Controller is running." = % && exit 0 || exit 1
