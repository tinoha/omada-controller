FROM ubuntu:20.04

LABEL org.opencontainers.image.title="omada-controller"\
 org.opencontainers.image.description="TP-Link Omada Software Controller"\
 org.opencontainers.image.base.name="docker.io/library/ubuntu:20.04"\
 org.opencontainers.image.version="5.7.4"

ENV TZ="Etc/UTC"

RUN apt-get -y update && apt-get -y upgrade && apt-get -y clean && apt-get -y autoremove

WORKDIR /omada

RUN apt-get -y install curl wget gnupg libcap2-bin sudo &&\
 wget -qO - https://www.mongodb.org/static/pgp/server-4.4.asc | apt-key add - &&\
 echo "deb [ arch=amd64,arm64 ] https://repo.mongodb.org/apt/ubuntu focal/mongodb-org/4.4 multiverse" | tee /etc/apt/sources.list.d/mongodb-org-4.4.list &&\
 apt-get update && apt-get -y install openjdk-8-jre-headless mongodb-org jsvc && apt-get -y clean && apt-get -y autoremove

COPY entrypoint.sh omada_sudoers $WORKDIR

RUN wget -q https://static.tp-link.com/upload/software/2022/202211/20221121/Omada_SDN_Controller_v5.7.4_Linux_x64.deb &&\
 apt-get -y install ./Omada_SDN_Controller_v5.7.4_Linux_x64.deb && tpeap stop && rm -f ./Omada_SDN_Controller_v5.7.4_Linux_x64.deb &&\
 chmod 0440 omada_sudoers && mv omada_sudoers /etc/sudoers.d

EXPOSE 8088 8043 8843 29810/udp 29811 29812 29813 29814

VOLUME [ "/opt/tplink/EAPController/logs", "/opt/tplink/EAPController/data" ]

USER omada

ENTRYPOINT ["/omada/entrypoint.sh"]

HEALTHCHECK --interval=5m --timeout=30s --start-period=3m --retries=2 \
 CMD sudo /usr/bin/tpeap status | cut -c -28 | xargs -I % test "Omada Controller is running." = % && exit 0 || exit 1
 