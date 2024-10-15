# Omada Software Controller

Container image for running TP-Link's [Omada Software Controller](https://www.tp-link.com/us/business-networking/omada-sdn-controller) to manage [Omada SDN network devices](https://www.tp-link.com/us/business-networking/all-omada/).

## About omada-controller image

Image is built by installing standard TP-Link provided Omada Controller [software package](https://www.tp-link.com/us/support/download/omada-software-controller/) `*.deb` and it's dependencies on a supported Ubuntu OS version (base image). No modifications were done to the original TP-Link provided software or files. Control (start/stop/status) of the Omada controller is implemented by utilizing the original `tpeap` scipt.

Image is built and tested with rootless Podman containers. However, as the omada control script `tpeap` can only be run as user root, sudo is used for invoking the script. Otherwise the container runs as non-root user (omada). Some extra linux capabilities are given to the container (--cap-add).

## Usage

### Start & Stop

Here is an example how to start and stop the controller. If you are using docker just replace the word podman with docker.

```
podman run -d \
  --restart unless-stopped \
  --cap-add=DAC_READ_SEARCH,SETGID,SETUID,NET_BIND_SERVICE \
  --name omada-controller \
  -e TZ=Etc/UTC \
  -v omada-logs:/opt/tplink/EAPController/logs \
  -v omada-data:/opt/tplink/EAPController/data \
  -p 8088:8088 -p 8043:8043 -p 8843:8843 -p 29810:29810/udp -p 29811:29811 -p 29812:29812 -p 29813:29813 -p 29814:29814 \
  --stop-timeout=300 \
  docker.io/tihal/omada-controller:<version>

podman stop omada-controller
```

Run arguments:<br>
`--e TZ=ETC/UTC` This is the default timezone of the image. To change the timezone see [TZ database](https://en.wikipedia.org/wiki/List_of_tz_database_time_zones) and pick a new value from column \"TZ database name\".
`--stop-timeout=300` This timer value allows 5 minutes for the container and it's applications to gracefully stop. Required time may depend on the MongoDB size and type of hardware. By default podman/docker only allows 10s for a container to stop after which it is forcefully stopped. Adjust the value as needed. `-p ...` These are the default ports needed by the Omada Controller to communicate.

Omada controller web interface:
http://localhost:8088

### Checking status and logs

Here is some examples how to check the status of the container and how to find the logs.

```
podman logs omada-controller
podman exec -it omada-controller sudo tpeap status
podman exec -it omada-controller ls -l /opt/tplink/EAPController/logs
podman exec -it omada-controller bash
```

### Backups

It is strongly recommended to take backups and keep them in a safe place. See TP-Link Omada Controller documentation how to perform both manual and automatic backups inside the app.

### Persistent storage

Persistent container data in /opt/tplink/EAPController/logs and /opt/tplink/EAPController/data are by default saved in unnamed volumes. Podman start example is using named volumes.

## Build

Build command:

```
podman build --cap-add=DAC_READ_SEARCH,SETGID,SETUID,NET_BIND_SERVICE \
 --format docker --file omada_v<version>.Dockerfile -t omada-controller:<version> .
```

Image [source](https://github.com/tinoha/omada-controller/) on GitHub.
