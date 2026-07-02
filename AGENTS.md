# AGENTS.md

Guidance for AI agents working in this repo. This repo packages TP-Link's Omada Software Controller into a container image; the Omada software itself is unmodified.

## Build

- Build command: `./build.sh --set-ver <version> [--file <dockerfile>]` (uses podman with `--format docker`).
  - `--set-ver` is always required. It is also the key used to locate an optional `versions/<version>.env` metadata file.
  - `--file` optionally overrides which Dockerfile is built. If omitted, the `DOCKERFILE` field from the env file is used. If neither is available the build errors out and asks the user to rerun with `--file`.
- `--help` lists versions from `versions/*.env` (derived, not hardcoded).
- **Env files** (`versions/<ver>.env`, shell-sourceable) use two namespaces, distinguished by prefix:
  - `BUILD_ARG_<NAME>="value"` → forwarded to `podman build` as `--build-arg <NAME>=value` (prefix stripped; only these become build-args). No fixed allowlist or required-set — a template that needs a new argument just adds a `BUILD_ARG_*` line.
  - Any other `<NAME>="value"` (e.g. `DOCKERFILE`) → consumed by `build.sh` only, never forwarded.
- **Build-args vs. no build-args**: whether build-args flow at all depends on whether the env file declares any `BUILD_ARG_*` entries — not on the `DOCKERFILE` value. The older `versions/*.env` files set only `DOCKERFILE`, so their standalone `omada_v*.Dockerfile` builds with zero build-args (baked-in `ARG` defaults stay in effect). Newer env files point `DOCKERFILE` at the shared template (`Dockerfile` at repo root) and declare the version-specifics as `BUILD_ARG_*`.
- **Image tag**: `BUILD_ARG_OMADA_VER` from the env file if set and non-empty, otherwise the `--set-ver` value. Single source of truth for the version.
- **v5.x capabilities**: `build.sh` auto-adds `--cap-add=DAC_READ_SEARCH,SETGID,SETUID,NET_BIND_SERVICE` when the tag starts with `5.`. v5.x installs via `.deb` and the service starts during build → caps required. v6.x uses `.tar.gz` + `install.sh init-cluster-mode` (no service start) → no caps. Do not pass caps manually.
- **Checksum**: `BUILD_ARG_OMADA_SHA512` in the env file, maintained manually (TP-Link publishes no official checksums). Set to empty to skip verification.
- **Adding a new version**: create `versions/<ver>.env` with `DOCKERFILE` set to the template or a standalone Dockerfile, and fill in the `BUILD_ARG_*` values as needed. `build.sh` needs no changes — it forwards whatever the env file declares.
- `legacy/build.sh` is the pre-refactor build script kept for reference. The older `omada_v*.Dockerfile` files at the repo root are kept for rebuilding previous versions and may break if upstream download URLs, package repos, or third-party artifacts change.

## CI / release flow

- CI workflow: `.github/workflows/container-image.yml`; behavior documented in `.github/workflows/README.md`.
- Branch lanes: `release/v*`, `deps/v*` build and push a `-dev` image to GHCR; `bugfix/v*`, `refactor/v*`, and `workflow-dev` are build-only (no publish). Version tags (`v*`) push to both GHCR and Docker Hub and create a GitHub release.
- `workflow-dev` builds a static v6.x tag (currently `6.2.10.17`) — use this lane to test workflow changes without a versioned branch.
- Runtime test: v6.x is run-tested post-build (`tpeap start` must report "Started successfully."); v5.x is not, because its `.deb` install starts the service during the build (caps are added by `build.sh`), so the build itself is the runtime test.
- Concurrency control cancels superseded branch runs; tag runs are never cancelled.
- Release policy: version tags (e.g. `6.2.10.17`) are immutable; container-only rebuilds use a revision suffix (e.g. `6.2.10.17-r1`); `-dev` tags are replaceable.

## Image runtime conventions

- Container runs as non-root user `omada` (UID/GID 550). `sudo` is restricted via `omada_sudoers` to `/usr/bin/tpeap` and `/opt/tplink/EAPController/bin/control.sh` only.
- `entrypoint.sh` starts `tpeap` and `wait`s on `sleep infinity`; traps SIGTERM/SIGINT to run `tpeap stop`. Use `--stop-timeout=300` (graceful shutdown can take minutes depending on MongoDB size).
- `healthcheck.sh` greps `tpeap status` for "Omada Controller is running." / "Omada Network Application is running." (the string differs by major version).
- v5.x images require `--cap-add=DAC_READ_SEARCH,SETGID,SETUID,NET_BIND_SERVICE` at runtime; v6.x runs with zero added caps.
- Persistent volumes: `/opt/tplink/EAPController/logs` and `/opt/tplink/EAPController/data`.

## Kubernetes

- `kubernetes/base` + Kustomize overlays `kubernetes/overlays/omada-v5.x` / `kubernetes/overlays/omada-v6.x`. The v5.x overlay adds capabilities; the v6.x overlay adds none.
- Kubernetes LoadBalancer services do not forward L2 broadcast, so Omada auto-discovery fails. Use Layer 3 adoption: DHCP Option 138 or a manually set Controller Inform URL.

## Verification

- There is no unit test, lint, or typecheck tooling in this repo.
- To verify a build locally: `./build.sh --set-ver <ver>`, then `podman run --rm localhost/omada-controller:<ver> sudo tpeap start` and confirm the output contains "Started successfully.".
