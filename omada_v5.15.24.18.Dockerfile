# Global Arguments
ARG TZ="Etc/UTC"
ARG OS_BASE="ubuntu:22.04"
ARG OMADA_VER="5.15.24.18"
ARG OMADA_DOWNLOAD_URL="https://static.tp-link.com/upload/software/2025/202507/20250703/omada_v5.15.24.18_linux_x64_20250630184434.deb"
ARG MONGO_VER="7.0.22"

# Stage 1: Build the jsvc binary
FROM ${OS_BASE} AS build-stage
  # Re-declare global args
  ARG TZ
  
  ENV TZ=${TZ} DEBIAN_FRONTEND="noninteractive"

  RUN apt-get -yq update && apt-get -yq dist-upgrade && \
      apt-get -yq install apt-utils curl openjdk-21-jdk-headless autoconf make gcc

  RUN curl -fsSL -O https://dlcdn.apache.org/commons/daemon/source/commons-daemon-1.4.1-src.tar.gz && \
      curl -fsSL -O https://downloads.apache.org/commons/daemon/source/commons-daemon-1.4.1-src.tar.gz.sha512 && \
      sha512sum -c commons-daemon-1.4.1-src.tar.gz.sha512 && \
      tar xvzf commons-daemon-1.4.1-src.tar.gz && \
      cd commons-daemon-1.4.1-src/src/native/unix/ && \
      sh support/buildconf.sh && \
      ./configure --with-java=/usr/lib/jvm/java-21-openjdk-amd64 && \ 
      make && \
      cp jsvc /usr/bin/

# Stage 2: Final
FROM ${OS_BASE} AS final-stage
# Re-declare global args
ARG TZ
ARG OS_BASE
ARG OMADA_VER
ARG OMADA_DOWNLOAD_URL
ARG MONGO_VER

ENV TZ=${TZ} DEBIAN_FRONTEND="noninteractive"

LABEL org.opencontainers.image.title="omada-controller"\
 org.opencontainers.image.description="TP-Link Omada Software Controller"\
 org.opencontainers.image.base.name="docker.io/library/${OS_BASE}"\
 org.opencontainers.image.version="${OMADA_VER}"

WORKDIR /omada
COPY entrypoint.sh omada_sudoers $WORKDIR
COPY --from=build-stage --chmod=555 /usr/bin/jsvc /usr/bin/

# Add repositories, update system and install prerequisites
RUN apt-get -yq update && apt-get -yq dist-upgrade && \  
  apt-get -yq install apt-utils curl gnupg sudo openjdk-21-jdk-headless && \
  curl -fsSL https://www.mongodb.org/static/pgp/server-7.0.asc | gpg -o /usr/share/keyrings/mongodb-server-7.0.gpg --dearmor && \
  echo "deb [ arch=amd64,arm64 signed-by=/usr/share/keyrings/mongodb-server-7.0.gpg ] https://repo.mongodb.org/apt/ubuntu jammy/mongodb-org/7.0 multiverse" | sudo tee /etc/apt/sources.list.d/mongodb-org-7.0.list && \
  apt-get -q update && \
  sudo apt-get install -y \
   mongodb-org=${MONGO_VER} \
   mongodb-org-database=${MONGO_VER} \
   mongodb-org-server=${MONGO_VER} \
   mongodb-mongosh \
   mongodb-org-shell=${MONGO_VER} \
   mongodb-org-mongos=${MONGO_VER} \
   mongodb-org-tools=${MONGO_VER} \
   mongodb-org-database-tools-extra=${MONGO_VER} && \
  apt-get -yq clean && apt-get -yq autoremove

# Install and configure Omada-Controller software
ENV JAVA_HOME=/usr/lib/jvm/java-21-openjdk-amd64
RUN groupadd -g 550 omada && useradd -u 550 -g omada -d /opt/tplink/EAPController/data -s /usr/sbin/nologin -M omada && \
  curl -fsSLO ${OMADA_DOWNLOAD_URL} && \
  OMADA_FILE="$(basename ${OMADA_DOWNLOAD_URL})" && \
  ls -l ./${OMADA_FILE} && \
  dpkg -i --ignore-depends=jsvc ./${OMADA_FILE} && \
  cat /opt/tplink/EAPController/logs/startup.log && \
  tpeap stop && rm -f ./${OMADA_FILE} && \
  chmod 0440 omada_sudoers && mv omada_sudoers /etc/sudoers.d

EXPOSE 8088 8043 8843 19810/udp 27001/udp 29810/udp 29811 29812 29813 29814 29815 29816

VOLUME [ "/opt/tplink/EAPController/logs", "/opt/tplink/EAPController/data" ]

USER omada

ENTRYPOINT ["/omada/entrypoint.sh"]

HEALTHCHECK --interval=5m --timeout=30s --start-period=2m --retries=2 \
 CMD sudo /usr/bin/tpeap status | cut -c -28 | xargs -I % test "Omada Controller is running." = % && exit 0 || exit 1
