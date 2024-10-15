FROM ubuntu:22.04

LABEL org.opencontainers.image.title="omada-controller"\
 org.opencontainers.image.description="TP-Link Omada Software Controller"\
 org.opencontainers.image.base.name="docker.io/library/ubuntu:22.04"\
 org.opencontainers.image.version="v5.14.26"

ENV TZ="Etc/UTC"

RUN apt-get -y update && apt-get -y upgrade && apt-get -y clean && apt-get -y autoremove

WORKDIR /omada


# Install Omada contoller prerequisites
RUN apt-get -y install curl gnupg sudo && \
 curl -fsSL https://www.mongodb.org/static/pgp/server-7.0.asc | \
 gpg -o /usr/share/keyrings/mongodb-server-7.0.gpg --dearmor && \
 echo "deb [ arch=amd64,arm64 signed-by=/usr/share/keyrings/mongodb-server-7.0.gpg ] https://repo.mongodb.org/apt/ubuntu jammy/mongodb-org/7.0 multiverse" | sudo tee /etc/apt/sources.list.d/mongodb-org-7.0.list && \
 apt-get update && \
 apt-get install -y mongodb-org=7.0.7 mongodb-org-database=7.0.7 mongodb-org-server=7.0.7 mongodb-mongosh mongodb-org-mongos=7.0.7 mongodb-org-tools=7.0.7 \
  openjdk-8-jre-headless jsvc && \
 apt-get -y clean && apt-get -y autoremove

COPY entrypoint.sh omada_sudoers $WORKDIR

# Install and configure Omada-Controller software 
RUN curl -L0O https://static.tp-link.com/upload/software/2024/202407/20240710/Omada_SDN_Controller_v5.14.26.1_linux_x64.deb &&\
 apt-get install -y ./Omada_SDN_Controller_v* && \
 tpeap stop && rm -f ./Omada_SDN_Controller_v* && \
 chmod 0440 omada_sudoers && mv omada_sudoers /etc/sudoers.d

EXPOSE 8088 8043 8843 29810/udp 29811 29812 29813 29814

VOLUME [ "/opt/tplink/EAPController/logs", "/opt/tplink/EAPController/data" ]

USER omada

ENTRYPOINT ["/omada/entrypoint.sh"]

HEALTHCHECK --interval=5m --timeout=30s --start-period=3m --retries=2 \
 CMD sudo /usr/bin/tpeap status | cut -c -28 | xargs -I % test "Omada Controller is running." = % && exit 0 || exit 1
 