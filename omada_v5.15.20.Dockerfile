# Stage 1: Build the jsvc binary
FROM ubuntu:22.04 AS build-stage
  ENV TZ="Etc/UTC" DEBIAN_FRONTEND="noninteractive"

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
FROM ubuntu:22.04 AS final-stage

LABEL org.opencontainers.image.title="omada-controller"\
 org.opencontainers.image.description="TP-Link Omada Software Controller"\
 org.opencontainers.image.base.name="docker.io/library/ubuntu:22.04"\
 org.opencontainers.image.version="5.15.20.16"

ENV TZ="Etc/UTC" DEBIAN_FRONTEND="noninteractive"

WORKDIR /omada
COPY entrypoint.sh omada_sudoers $WORKDIR
COPY --from=build-stage --chmod=555 /usr/bin/jsvc /usr/bin/

# Add repositories, update system and install prerequisites
RUN apt-get -yq update && apt-get -yq dist-upgrade && \  
  apt-get -yq install apt-utils curl gnupg sudo openjdk-17-jdk-headless && \
  curl -fsSL https://www.mongodb.org/static/pgp/server-7.0.asc | gpg -o /usr/share/keyrings/mongodb-server-7.0.gpg --dearmor && \
  echo "deb [ arch=amd64,arm64 signed-by=/usr/share/keyrings/mongodb-server-7.0.gpg ] https://repo.mongodb.org/apt/ubuntu jammy/mongodb-org/7.0 multiverse" | sudo tee /etc/apt/sources.list.d/mongodb-org-7.0.list && \
  apt-get -q update && \
  apt-get -yq install mongodb-org=7.0.18 mongodb-org-database=7.0.18 mongodb-org-server=7.0.18 mongodb-mongosh mongodb-org-mongos=7.0.18 mongodb-org-tools=7.0.18 && \
  apt-get -yq clean && apt-get -yq autoremove && rm -rf /var/lib/apt/lists/*

# Install and configure Omada-Controller software
ENV JAVA_HOME=/usr/lib/jvm/java-17-openjdk-amd64
RUN groupadd -g 550 omada && useradd -u 550 -g omada -d /opt/tplink/EAPController/data -s /usr/sbin/nologin -M omada && \
 curl -LO https://static.tp-link.com/upload/software/2025/202503/20250321/Omada_SDN_Controller_v5.15.20.16_linux_x64.deb && \
 ls -l ./Omada_SDN_Controller_v5.15.20.16_linux_x64.deb && \
 dpkg -i --ignore-depends=jsvc ./Omada_SDN_Controller_v5.15.20.16_linux_x64.deb && \
 cat /opt/tplink/EAPController/logs/startup.log && \
 tpeap stop && rm -f ./Omada_SDN_Controller_v5.15.20.16_linux_x64.deb && \
 chmod 0440 omada_sudoers && mv omada_sudoers /etc/sudoers.d

EXPOSE 8088 8043 8843 29810/udp 29811 29812 29813 29814

VOLUME [ "/opt/tplink/EAPController/logs", "/opt/tplink/EAPController/data" ]

USER omada

ENTRYPOINT ["/omada/entrypoint.sh"]

HEALTHCHECK --interval=5m --timeout=30s --start-period=2m --retries=2 \
 CMD sudo /usr/bin/tpeap status | cut -c -28 | xargs -I % test "Omada Controller is running." = % && exit 0 || exit 1
