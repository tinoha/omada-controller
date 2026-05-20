# Omada Software Controller
[![Container Image CI](https://github.com/tinoha/omada-controller/actions/workflows/container-image.yml/badge.svg)](https://github.com/tinoha/omada-controller/actions/workflows/container-image.yml)

Container image for running TP-Link's [Omada Software Controller](https://www.omadanetworks.com/us/business-networking/omada-controller-cloud-software/omada-software-controller/) to manage [Omada SDN network devices](https://www.tp-link.com/us/business-networking/all-omada/).

## About the Omada-Controller Image
The image is built by installing TP-Link's standard Omada Controller [software package](https://www.tp-link.com/us/support/download/omada-software-controller/) and its dependencies on a Ubuntu OS base image. No modifications are made to the original TP-Link software or files. Control (start/stop/status) of the Omada controller is implemented using the original `tpeap` script.

The image is built and tested with rootless Podman containers. The container runs as a non-root user (`omada`) by default, while `sudo` is used only to invoke the `tpeap` control script, which requires root privileges.

## Software Versions in Image Releases
| Image Tag    | Omada Controller | Ubuntu | Java(JDK)  | JSVC   | MongoDB | Notes                 |
| ------------ | ---------------- | ------ | ---------- | ------ | ------- | --------------------- |
| `6.2.10.17`  | 6.2.10.17       | 24.04  | OpenJDK 21 | 1.4.1  | 8.0.23  | Release 6.2.10.17     |
| `6.2.0.17`   | 6.2.0.17         | 24.04  | OpenJDK 21 | 1.4.1  | 8.0.23  | Release 6.2.0.17      |
| `6.1.0.19`   | 6.1.0.19         | 24.04  | OpenJDK 21 | 1.4.1  | 8.0.20  | Release 6.1.0.19      |
| `6.0.0.25`   | 6.0.0.25         | 24.04  | OpenJDK 25 | 1.5.1  | 8.0.17  | Release 6.0.0.25      |
| `6.0.0.24`   | 6.0.0.24         | 24.04  | OpenJDK 25 | 1.4.1  | 8.0.15  | Release 6.0.0.24      |
| `5.15.24.18` | 5.15.24.18       | 22.04  | OpenJDK 21 | 1.4.1  | 7.0.22  | Release 5.15.24.18    |
| `5.15.24.17` | 5.15.24.17       | 22.04  | OpenJDK 21 | 1.4.1  | 7.0.21  | Release 5.15.24.17    |
| `5.15.20.18` | 5.15.20.18       | 22.04  | OpenJDK 21 | 1.4.1  | 7.0.18  | Release 5.15.20.18    |
| `5.15.20-1`  | 5.15.20.16       | 22.04  | OpenJDK 21 | 1.4.1  | 7.0.18  | fix:Add missing ports |
| `5.15.20`    | 5.15.20.16       | 22.04  | OpenJDK 21 | 1.4.1  | 7.0.18  | Release 5.15.20.16    |
| `5.14.26`    | 5.14.26.1        | 22.04  | OpenJDK 8  | 1.0.15 | 7.0.7   | Release 5.14.26.1     |

**Notes:**

- The `vX.Y.Z-N` format indicates updates to dependencies, scripts or Dockerfile while keeping the Omada version unchanged.
- Only the latest few versions are available for download due to large image size (~2GB). If you rely on a specific version, please **keep a local copy** of the image. Alternatively, you can rebuild older versions using the provided `Dockerfiles`.
- Based on my experience, TP-Link documentation for required dependency versions (Java, jsvc, Ubuntu) is not always fully consistent across sources and appears to provide general guidance rather than a strict compatibility matrix.
- The images provided here do not strictly follow the documented combinations, but instead use a set of versions that have been validated during build time and through continuous operation in my home environment. You may adjust the Dockerfile to use alternative versions based on your own requirements.

## Usage on Docker/Podman

### Start & Stop
Here is an example of how to start and stop the controller. If you are using Docker, replace the word podman with docker.
Note: Image versions v5.x require `--cap-add` while v6.x does not.

For v6.x images:
```bash
podman run -d \
  --restart unless-stopped \
  --name omada-controller \
  -e TZ=Etc/UTC \
  -v omada-logs:/opt/tplink/EAPController/logs \
  -v omada-data:/opt/tplink/EAPController/data \
  -p 8088:8088 \
  -p 8043:8043 \
  -p 8843:8843 \
  -p 19810:19810/udp \
  -p 27001:27001/udp \
  -p 29810:29810/udp \
  -p 29811:29811 \
  -p 29812:29812 \
  -p 29813:29813 \
  -p 29814:29814 \
  -p 29815:29815 \
  -p 29816:29816 \
  -p 29817:29817 \
  --stop-timeout=300 \
  docker.io/tihal/omada-controller:<version>
```
For v5.x images:
```bash
podman run -d \
  --restart unless-stopped \
  --name omada-controller \
  --cap-add=DAC_READ_SEARCH,SETGID,SETUID,NET_BIND_SERVICE \
  -e TZ=Etc/UTC \
  -v omada-logs:/opt/tplink/EAPController/logs \
  -v omada-data:/opt/tplink/EAPController/data \
  -p 8088:8088 \
  -p 8043:8043 \
  -p 8843:8843 \
  -p 19810:19810/udp \
  -p 27001:27001/udp \
  -p 29810:29810/udp \
  -p 29811:29811 \
  -p 29812:29812 \
  -p 29813:29813 \
  -p 29814:29814 \
  -p 29815:29815 \
  -p 29816:29816 \
  --stop-timeout=300 \
  docker.io/tihal/omada-controller:<version>
``` 
Run arguments:
- `-e TZ=Etc/UTC` This is the default timezone of the image. To change the timezone see [TZ database](https://en.wikipedia.org/wiki/List_of_tz_database_time_zones) and pick a new value from the \"TZ database name\" column.
- `--stop-timeout=300` This timer value allows 5 minutes for the container and it's applications to gracefully stop. Required time may depend on the MongoDB size and type of hardware. By default podman/docker only allows 10s for a container to stop after which it is forcefully stopped. Adjust the value based on your needs.
- `-p ...` These are the default ports needed by the Omada Controller to communicate.

The Omada Controller web interface can be accessed at:
http://localhost:8088

### Checking status and logs
Here are some examples how to check the status of the container and how to find the logs.

```bash
podman logs omada-controller
podman exec -it omada-controller sudo tpeap status
podman exec -it omada-controller ls -l /opt/tplink/EAPController/logs
podman exec -it omada-controller bash
```

### Persistent storage
Persistent container data in `/opt/tplink/EAPController/logs` and `/opt/tplink/EAPController/data` is by default stored in unnamed volumes. The example Podman start command is using named volumes for data persistence.

## Kubernetes Deployment
For Kubernetes environments, example manifests are provided in the `kubernetes` directory. These manifests offer a starting point to deploy the Omada Controller container image on Kubernetes. Adjustments may be needed to match your specific environment.

`Kustomize` overlays provide two deployment methods depending on the Omada Controller image version. The primary difference between the deployments is that v5.x images require additional capabilities, while v6.x images run with zero added capabilities.

```bash
# For v5.x images
kubectl kustomize kubernetes/overlays/omada-v5.x                       # Review first what will be deployed
kubectl kustomize kubernetes/overlays/omada-v5.x | kubectl apply -f -  # to deploy 

# For v6.x images
kubectl kustomize kubernetes/overlays/omada-v6.x                       # Review first what will be deployed
kubectl kustomize kubernetes/overlays/omada-v6.x | kubectl apply -f -  # to deploy
```

Please note, Kubernetes LoadBalancer services do not typically forward Layer 2 (L2) broadcast traffic that the Omada Controller uses for auto-discovery. This means devices will not appear automatically for adoption.

To fix this, you need to use a Layer 3 adoption method:
- `DHCP Option 138`: Configure your DHCP server to provide the controller's IP or hostname to the devices.
- `Manual Inform URL`: Manually set the Controller Inform URL in each device's settings to point to your controller.

## Backups
It's strongly recommended to create backups and store them in a safe location. For instructions on performing manual and automatic backups, refer to the TP-Link Omada Controller documentation.

## Build
To build the images, use the podman build (or docker build) command.
Note: The build command is different for v5.x and v6.x images due to differences how dependencies and Omada software is installed during build.

For v6.x Images:
The v6.x build uses the *.tar.gz package and its install script with `init-cluster-mode` option, which prevents starting the service during the build. No additional capabilities needed.
```bash
podman build \
  --format docker \
  --file omada_<version>.Dockerfile \
  -t omada-controller:<version> .
```

For v5.x Images:
The v5.x build uses the .deb package, which attempts to start the controller during installation. This requires the build process to have the necessary capabilities, to succesfully start the service.
```bash
podman build \
  --cap-add=DAC_READ_SEARCH,SETGID,SETUID,NET_BIND_SERVICE \
  --format docker \
  --file omada_<version>.Dockerfile \
  -t omada-controller:<version> .
```
For more information, visit the image source repository at [source](https://github.com/tinoha/omada-controller/) on GitHub.

## Support and Feedback

This image is built and maintained as part of my personal home network setup, where I use Omada Software Controller to manage TP-Link devices. I occasionally update the image based on new Omada releases, but I cannot guarantee regular updates.

This project is not affiliated with, endorsed by, or supported by TP-Link. For issues with the Omada software itself, please refer to TP-Link’s official support channels.

If you encounter issues specific to this container image or have suggestions for improvement, feel free to contact me at tinoha10@outlook.com. I’ll do my best to improve the project as time allows.

Your feedback is appreciated!

## License

My personal work, including the scripts, Dockerfile, and configuration files in this repository, are licensed under the MIT License. See the [LICENSE](https://github.com/tinoha/omada-controller/blob/main/LICENSE.txt) file for details.

### Third-Party Software
This project provides an unofficial container image for TP-Link Omada Software Controller. It is not affiliated with, endorsed by, or supported by TP-Link.

The TP-Link Omada Software Controller is third-party software and is licensed separately by TP-Link. This project does not modify the Omada application itself; the container image installs and runs the Omada software from TP-Link’s official download source.

This project also uses MongoDB, Java, the Ubuntu base image, and other third-party software, each of which is licensed separately. Please consult each respective software’s documentation for detailed licensing information. This statement also applies to any other third-party software included in this project, whether specifically listed or not.
