# Omada Software Controller

[![Container Image CI](https://github.com/tinoha/omada-controller/actions/workflows/container-image.yml/badge.svg)](https://github.com/tinoha/omada-controller/actions/workflows/container-image.yml)
[![GitHub Release](https://img.shields.io/github/v/release/tinoha/omada-controller?sort=semver)](https://github.com/tinoha/omada-controller/releases/latest)

Container image for running TP-Link's [Omada Software Controller](https://www.omadanetworks.com/us/business-networking/omada-controller-cloud-software/omada-software-controller/) to manage [Omada SDN network devices](https://www.tp-link.com/us/business-networking/all-omada/).

This repository packages the official TP-Link Omada Software Controller for containerized environments, keeping the build process transparent and reproducible. The image is designed to be a well-documented container image that closely follows the upstream software without hidden modifications — the contents and build process of every published image should be easy to inspect, understand and reproduce.

## Table of Contents

- [Quick Start](#quick-start)
- [About](#about)
- [Published Image Versions](#published-image-versions)
- [Tags](#tags)
- [Usage](#usage)
- [Persistence](#persistence)
- [Build](#build)
- [Support](#support)
- [Disclaimer](#disclaimer)
- [License](#license)

## Quick Start

The image is built and tested with Podman, but is also compatible with Docker. To run the latest supported Omada Controller v6.x release:

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
  -p 29811-29817:29811-29817 \
  --stop-timeout=300 \
  docker.io/tihal/omada-controller:<version>
```

Replace `<version>` with a tag from the [Published Image Versions](#published-image-versions) table (for example `6.2.10.17`).

After the container has started, the Omada Controller web interface is available at `http://localhost:8088`.

Note: Omada Controller **v5.x** images require additional Linux capabilities (`--cap-add`); **v6.x** images do not. See [Usage](#usage) for complete examples for both.

## About

The image is created by installing the official TP-Link Omada Software Controller package together with its required dependencies on an Ubuntu base image. No modifications are made to the Omada application or its files. Controller lifecycle management (start, stop and status) uses TP-Link's original `tpeap` script.

The container runs as the non-root user `omada` (UID/GID 550) by default. `sudo` is used only to invoke the `tpeap` control script, which requires root privileges.

A health check periodically runs `tpeap status` and reports the controller status to the container runtime. This allows orchestrators and monitoring systems to detect an unhealthy controller.

The build process is intentionally transparent. Image versions, download URLs, checksums, operating system versions and runtime dependencies are tracked in this repository so that image contents can be verified and reproduced.

### Features

- Available for `linux/amd64`.
- Uses the official TP-Link Omada Software Controller packages.
- No modifications are made to the Omada application or its files.
- Runs as a non-root user by default.
- Built and tested with Podman; compatible with Docker.
- Versioned, reproducible build process.
- Kubernetes deployment examples included.
- Image contents and dependency versions are fully documented.

## Published Image Versions

The table below shows which Omada Software Controller version is packaged in each published image together with its major runtime dependencies.

| Image Tag    | Omada Controller | Ubuntu | Java (JDK) | JSvc | MongoDB | Notes                 |
| ------------ | ---------------- | ------ | ---------- | ---- | ------- | --------------------- |
| `6.2.10.17`  | 6.2.10.17        | 24.04  | OpenJDK 21 | 1.4.1 | 8.0.23  | Release 6.2.10.17     |
| `6.2.0.17`   | 6.2.0.17         | 24.04  | OpenJDK 21 | 1.4.1 | 8.0.23  | Release 6.2.0.17      |
| `6.1.0.19`   | 6.1.0.19         | 24.04  | OpenJDK 21 | 1.4.1 | 8.0.20  | Release 6.1.0.19      |
| `6.0.0.25`   | 6.0.0.25         | 24.04  | OpenJDK 25 | 1.5.1 | 8.0.17  | Release 6.0.0.25      |
| `6.0.0.24`   | 6.0.0.24         | 24.04  | OpenJDK 25 | 1.4.1 | 8.0.15  | Release 6.0.0.24      |
| `5.15.24.18` | 5.15.24.18       | 22.04  | OpenJDK 21 | 1.4.1 | 7.0.22  | Release 5.15.24.18    |
| `5.15.24.17` | 5.15.24.17       | 22.04  | OpenJDK 21 | 1.4.1 | 7.0.21  | Release 5.15.24.17    |
| `5.15.20.18` | 5.15.20.18       | 22.04  | OpenJDK 21 | 1.4.1 | 7.0.18  | Release 5.15.20.18    |
| `5.15.20-1`  | 5.15.20.16       | 22.04  | OpenJDK 21 | 1.4.1 | 7.0.18  | Container revision    |
| `5.15.20`    | 5.15.20.16       | 22.04  | OpenJDK 21 | 1.4.1 | 7.0.18  | Release 5.15.20.16    |
| `5.14.26`    | 5.14.26.1        | 22.04  | OpenJDK 8  | 1.0.15 | 7.0.7   | Release 5.14.26.1     |

Older image versions may be removed over time to reduce registry storage requirements. If you rely on a specific version, keep a local copy or [build your own image](#build).

### Upgrading

As a general procedure for upgrading the image: back up your controller data, stop and remove the old container (named volumes are preserved), then start a new container with the new image tag using the same volumes.

Always check the release notes for the version you are targeting — the bundled database and dependencies may change between series, and downgrades are typically not possible. This is especially relevant for major upgrades (for example v5.x → v6.x).

Refer to TP-Link's [Omada Software Controller release notes](https://www.tp-link.com/us/support/download/omada-software-controller/) and [knowledgebase](https://support.omadanetworks.com/us/document/?documentResourceTypeIdList=1116,1117,1118) for supported upgrade paths and version-specific prerequisites.

## Tags

This image does not publish a `latest` tag — pin a specific version tag for reproducible deployments.

Published release tags are intended to be immutable. Tags matching the Omada Software Controller version (for example `6.2.10.17`) identify the first container image built for that upstream release. If the image is rebuilt while the bundled Omada Controller version remains unchanged — for example to address container packaging, dependency or base image updates — a revision suffix is appended, for example `6.2.10.17-r1`.

Development tags ending in `-dev` are intended for testing and may be replaced or removed without notice.

## Usage

The examples below use **Podman**. To use **Docker**, simply replace `podman` with `docker`.

### Omada Controller v6.x

Omada Controller v6.x images require no additional Linux capabilities.

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
  -p 29811-29817:29811-29817 \
  --stop-timeout=300 \
  docker.io/tihal/omada-controller:<version>
```

### Omada Controller v5.x

Omada Controller v5.x images require additional Linux capabilities because the TP-Link `.deb` package starts the controller during installation.

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
  -p 29811-29816:29811-29816 \
  --stop-timeout=300 \
  docker.io/tihal/omada-controller:<version>
```

### Runtime Arguments

The examples above use the following runtime options.

| Argument | Description |
|----------|-------------|
| `-e TZ=Etc/UTC` | Sets the container timezone. Replace with a value from the [TZ database](https://en.wikipedia.org/wiki/List_of_tz_database_time_zones) (pick from the "TZ database name" column, for example `Europe/Helsinki`). |
| `-v omada-data:/opt/tplink/EAPController/data` | Stores the controller database and configuration persistently. |
| `-v omada-logs:/opt/tplink/EAPController/logs` | Stores controller log files persistently. |
| `--stop-timeout=300` | Allows up to five minutes for the controller and MongoDB to shut down cleanly before the container runtime terminates the process. The default in Docker/Podman is only 10 seconds. Increase the value if your installation contains a large database or runs on slower storage. |
| `-p ...` | Publishes the network ports required by the Omada Controller. |

### Logs and Status

The following commands are useful for monitoring the controller and troubleshooting problems:

```bash
# Display the container logs
podman logs omada-controller

# Check the Omada Controller status
podman exec -it omada-controller sudo tpeap status

# List controller log files
podman exec -it omada-controller ls -l /opt/tplink/EAPController/logs

# Open a shell inside the container
podman exec -it omada-controller bash
```

### Kubernetes

Example Kubernetes manifests are provided in the `kubernetes/` directory. They are intended as a starting point and may require adjustments for your environment. Kustomize overlays are provided for both supported image generations:

- **v5.x** images (additional Linux capabilities required)
- **v6.x** images (no additional capabilities required)

Review the generated manifests before deployment:

```bash
# Review what will be deployed (v5.x or v6.x)
kubectl kustomize kubernetes/overlays/omada-v6.x

# Deploy once you are happy with the output
kubectl kustomize kubernetes/overlays/omada-v6.x | kubectl apply -f -
```

Use `kubernetes/overlays/omada-v5.x` in place of `omada-v6.x` for v5.x images.

Kubernetes `LoadBalancer` services generally do not forward Layer 2 broadcast traffic, so Omada devices will typically **not** appear automatically for adoption. Use one of the supported Layer 3 adoption methods instead:

- **DHCP Option 138**: Configure your DHCP server to advertise the controller address to the devices.
- **Manual Inform URL**: Manually set the Controller Inform URL in each device's settings to point to your controller.

Refer to the TP-Link documentation for details appropriate to your network environment.

## Persistence

The Omada Controller stores persistent data in the following directories:

| Directory | Purpose |
|-----------|---------|
| `/opt/tplink/EAPController/data` | Controller database and configuration |
| `/opt/tplink/EAPController/logs` | Controller log files |

The example commands use named container volumes. Bind mounts may also be used if preferred. When using bind mounts, note that the container runs as user `omada` with UID/GID `550` — ensure the host directories are owned by, or writable for, UID/GID `550` so the controller can read and write its data.

Removing the container does **not** remove named volumes. If persistent storage is required, keep the named volumes rather than relying on ephemeral ones.

### Backups

It's strongly recommended to create backups and store them in a safe location. The Omada Controller provides both manual and scheduled backup functionality — store backup files outside the container and verify that they can be restored before relying on them for disaster recovery. For instructions, refer to the TP-Link Omada Controller documentation.

## Build

The repository ships a build script, `build.sh`, that wraps `podman build` and keeps per-version metadata in small env files under `versions/`. This keeps builds reproducible and avoids hardcoding versions or download URLs inside the Dockerfiles. Newer image releases use a shared Dockerfile together with version-specific metadata, while older releases are still supported through their original standalone `omada_v*.Dockerfile` files at the repo root.

### Supported versions

Run `./build.sh --help` to list the versions that ship with an env file. The list is derived from `versions/*.env`, so it stays in sync with what is in the repo.

### Building an image

To build a version that has an env file:

```bash
./build.sh --set-ver <version>
```

For example, `./build.sh --set-ver 6.2.10.17`.

For a version without an env file, point `--file` at a Dockerfile explicitly:

```bash
./build.sh --set-ver <version> --file <path/to/Dockerfile>
```

### What `build.sh` does

For a given `--set-ver <version>`, `build.sh` looks for `versions/<version>.env`. If it exists, variables are read from it:

- `BUILD_ARG_<NAME>="value"` — forwarded to `podman build` as `--build-arg <NAME>=value` (the `BUILD_ARG_` prefix is stripped). If the file declares none, zero build-args are passed and the Dockerfile's baked-in `ARG` defaults stay in effect.
- Any other `<NAME>="value"` — used by `build.sh` itself and never forwarded. The `DOCKERFILE` field is one of these; it selects which Dockerfile to build.

If no `versions/<version>.env` exists, `build.sh` requires `--file <path>` to point at the Dockerfile to build, and builds it with no build-args.
The resulting image tag is `BUILD_ARG_OMADA_VER` from the env file if set, otherwise the value passed to `--set-ver`.

Note: v5.x builds use the `.deb` package, which starts the controller during installation and requires capabilities. `build.sh` adds `--cap-add=DAC_READ_SEARCH,SETGID,SETUID,NET_BIND_SERVICE` automatically when the tag starts with `5.`, so you do not need to pass caps manually. v6.x uses the `.tar.gz` package and needs none.

For more information, visit the [source repository](https://github.com/tinoha/omada-controller/) on GitHub.

## Support

This image is built and maintained as part of my personal home network setup, where I use the Omada Software Controller to manage TP-Link devices. I occasionally update the image based on new Omada releases, but I cannot guarantee a regular update schedule.

If you encounter issues specific to this container image or the build process, feel free to contact me at tinoha10@outlook.com — I'll do my best to improve the project as time allows. Your feedback is appreciated!

For issues with the Omada software itself, please refer to TP-Link's official support channels.

## Disclaimer

This project is **not affiliated with, endorsed by, or supported by TP-Link**. "Omada" and related product names are trademarks of TP-Link and are used solely to identify the software supported by this project.

This project provides an unofficial container image for the TP-Link Omada Software Controller. The Omada application is TP-Link's proprietary software, downloaded from TP-Link's official distribution source during the image build and used unmodified.

## License

The scripts, Dockerfiles and other original files in this repository are licensed under the MIT License. See the [LICENSE](LICENSE.txt) file for details.

### Third-Party Software

This project installs third-party software that remains subject to its respective licenses, including, but not limited to:

- TP-Link Omada Software Controller
- Ubuntu
- MongoDB
- OpenJDK
- Apache Commons Daemon (jsvc)

This project does not modify, relicense or claim ownership of any third-party software included in the container image.