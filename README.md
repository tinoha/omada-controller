# Omada Software Controller

Container image for TP-Link's [Omada Software Controller](https://www.tp-link.com/us/business-networking/omada-sdn-controller) for managing [Omada SDN networking devices](https://www.tp-link.com/us/business-networking/all-omada).

## About omada-controller image
Image is for running the Omada Controller inside a rootless Podman container. However, as the omada control script `tpeap` can only be run as user root, sudo is used for invoking the script. In addition some extra linux capabilities are given for the container (--cap-add).

Image is built by installing standard TP-Link provided Omada Controller [software package](https://www.tp-link.com/us/support/download/omada-software-controller/) `*.deb` and it's dependencies on a supported base OS image version. No modifications were done to the original TP-Link provided software and files. Also the control activities (start/stop/status) are performed by using the original `tpeap`tool.

## Usage

### Start & Stop
Example how to start the the controller.

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
  docker.io/tihal/omada-controller:5.7.4

podman stop omada-controller
```

Adjust run parameters as needed, e.g.:
`--e TZ=ETC/UTC`  This is the default timezone of the image. You may adjust as needed, see [TZ database]( https://en.wikipedia.org/wiki/List_of_tz_database_time_zones) for other value
`--stop-timeout=300` This timer allows 5 minutes for the container and it's applications to gracefully stop. Adjust as needed. Required time depends on the MongoDB size and type of hardware. By default podman/docker only allows 10s for a container to stop after wich it is forcefully stopped.
`-p ...`  These are the default ports required by the Omada Controller. 

### Checking status and logs
Some examples how to check the status of the container and Omada controller 

```
podman logs omada-controller
podman exec -it omada-controller sudo tpeap status
podman exec -it omada-controller ls /opt/tplink/EAPController/logs
podman exec -it omada-controller tail -f /opt/tplink/EAPController/logs/mongod.log
```

### Backups
It is strongly recommended to take backups and keep them in a safe place. See offical TP-Link Omada Controller documentation how to perform both manual and automatic backups.  

### Persistent storage
Persistent container data in /opt/tplink/EAPController/logs and /opt/tplink/EAPController/data are by default saved in unnamed volumes. Podman start example is using named volumes. 

## Test

## Build
Build command 
```
podman build --cap-add=DAC_READ_SEARCH,SETGID,SETUID,NET_BIND_SERVICE \
  --format docker -t docker.io/tihal/omada-controller:5.7.4 .
```

## Issues


## Links