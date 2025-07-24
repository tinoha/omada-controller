# Omada Software Controller

Container image for running TP-Link's [Omada Software Controller](https://www.omadanetworks.com/us/business-networking/omada-controller-cloud-software/omada-software-controller/) to manage [Omada SDN network devices](https://www.tp-link.com/us/business-networking/all-omada/).

## About the Omada-Controller Image

The image is built by installing TP-Link's standard Omada Controller [software package](https://www.tp-link.com/us/support/download/omada-software-controller/) `*.deb` and its dependencies on a supported Ubuntu OS base image. No modifications were done to the original TP-Link provided software or files. Control (start/stop/status) of the Omada controller is implemented by utilizing the original `tpeap` script.

Image is built and tested with rootless Podman containers. However, as the omada control script `tpeap` can only be run as user root, `sudo` is used for invoking the script. Otherwise the container runs as non-root user (omada). Some extra linux capabilities are given to the container (`--cap-add`).

## Software Versions in Image Releases

| Image Tag    | Omada Controller | Ubuntu | Java(JDK)      | JSVC   | MongoDB | Notes                 |
| ------------ | ---------------- | ------ | -------------- | ------ | ------- | --------------------- |
| `5.15.24.18` | 5.15.24.18       | 22.04  | OpenJDK 21.0.7 | 1.4.1  | 7.0.22  | Release 5.15.24.18    |
| `5.15.24.17` | 5.15.24.17       | 22.04  | OpenJDK 21.0.7 | 1.4.1  | 7.0.21  | Release 5.15.24.17    |
| `5.15.20.18` | 5.15.20.18       | 22.04  | OpenJDK 21.0.6 | 1.4.1  | 7.0.18  | Release 5.15.20.18    |
| `5.15.20-1`  | 5.15.20.16       | 22.04  | OpenJDK 21.0.6 | 1.4.1  | 7.0.18  | fix:Add missing ports |
| `5.15.20`    | 5.15.20.16       | 22.04  | OpenJDK 21.0.6 | 1.4.1  | 7.0.18  | Release 5.15.20.16    |
| `5.14.26`    | 5.14.26.1        | 22.04  | OpenJDK 8      | 1.0.15 | 7.0.7   |

**Notes:**

- The `vX.Y.Z-N` format indicates updates to dependencies, scripts or Dockerfile while keeping the Omada version unchanged.
- Only the latest few versions are available for download due to large image size (~2GB). If you rely on a specific version, please **keep a local copy** of the image. Alternatively, you can rebuild older versions using the provided `Dockerfile`.

## Usage on Docker/Podman

### Start & Stop

Here is an example of how to start and stop the controller. If you are using Docker, replace the word podman with docker.

```bash
podman run -d \
  --restart unless-stopped \
  --cap-add=DAC_READ_SEARCH,SETGID,SETUID,NET_BIND_SERVICE \
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
  --stop-timeout=300 \
  docker.io/tihal/omada-controller:<version>


```

Run arguments:

- `--e TZ=Etc/UTC` This is the default timezone of the image. To change the timezone see [TZ database](https://en.wikipedia.org/wiki/List_of_tz_database_time_zones) and pick a new value from the \"TZ database name\" column.
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

## Backups

It's strongly recommended to create backups and store them in a safe location. For instructions on performing manual and automatic backups, refer to the TP-Link Omada Controller documentation.

## Build

To build the image use following command:

```bash
podman build --cap-add=DAC_READ_SEARCH,SETGID,SETUID,NET_BIND_SERVICE \
 --format docker --file omada_v<version>.Dockerfile -t omada-controller:<version> .
```

For more information, visit the image source repository at [source](https://github.com/tinoha/omada-controller/) on GitHub.

## Support and Feedback

This image is built and maintained as part of my personal home network setup, where I use the Omada Controller to manage TP-Link devices. While I occasionally update the image based on new Omada releases, I cannot offer official support or guarantee regular updates.

If you encounter any issues or have suggestions, feel free to contact me at tinoha10@outlook.com. I’ll do my best to improve the project as time allows.

Your feedback is appreciated!

## License

My personal work, including the scripts, Dockerfile, and configuration files in this repository, are licensed under the MIT License. See the [LICENSE](https://github.com/tinoha/omada-controller/blob/main/LICENSE.txt) file for details.

### Third-Party Software

This project uses TP-Link Omada Controller, MongoDB, Java, and the Ubuntu base image, which are each licensed separately. Please consult each respective software’s documentation for detailed licensing information. This statement also applies to any other third-party software included in this project, whether specifically listed or not.
