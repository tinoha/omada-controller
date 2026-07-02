# Container Image CI

The workflow in `container-image.yml` builds, tests, and publishes the Omada Controller container image. It runs on push to versioned branches and version tags, and on the `workflow-dev` branch for workflow testing.

## How it works

1. **Set IMAGE_TAG and push intent** — determines the Omada version from the branch or tag name, and whether the image should be published (`PUSH=true`) or only built as a verification step.
2. **Build** — runs `./build.sh --set-ver <IMAGE_TAG>`, which sources `versions/<IMAGE_TAG>.env` and builds the image with podman.
3. **Test** (v6.x only) — runs the container and confirms `tpeap start` reports "Started successfully.".
4. **Push to GHCR** — only when `PUSH=true`. Dev branches get a `-dev` suffix; tags get no suffix.
5. **Push to Docker Hub + GitHub release** — only for version tags (`refs/tags/v*`).

## Trigger behavior

| Trigger | Build | Runtime test | Push GHCR | Push Docker Hub | GitHub release |
| ---------- | :---: | :---: | :---: | :---: | :---: |
| tag `v6.2.10.17` | yes | yes (v6.x) | `6.2.10.17` | `6.2.10.17` | yes |
| tag `v5.15.24.18` | yes | no (v5.x) | `5.15.24.18` | `5.15.24.18` | yes |
| `release/v*` | yes | yes (v6.x) | `<ver>-dev` | no | no |
| `deps/v*` | yes | yes (v6.x) | `<ver>-dev` | no | no |
| `bugfix/v*` | yes | yes (v6.x) | no | no | no |
| `refactor/v*` | yes | yes (v6.x) | no | no | no |
| `workflow-dev` | yes | yes (v6.x) | no | no | no |

- **Publishing lanes** (`release/`, `deps/`) push a `-dev` preview image to GHCR. Use these when the change alters the published artifact (new Omada version, dependency update).
- **Build-only lanes** (`bugfix/`, `refactor/`, `workflow-dev`) verify the build succeeds but do not publish. Use these for changes to internal tooling, build scripts, or the workflow itself where the resulting image is unchanged.
- **Tags** are the full release path: both registries plus a GitHub release. Tags are immutable.

## Branch naming convention

| Prefix | Purpose | Publishes? |
| ---------- | ---------- | :---: |
| `release/v<ver>` | New Omada controller version | `-dev` to GHCR |
| `deps/v<ver>` | Dependency update (Mongo, Java, Ubuntu, jsvc) | `-dev` to GHCR |
| `bugfix/v<ver>` | Build process fix (no image change) | no |
| `refactor/v<ver>` | Internal restructuring (no image change) | no |
| `workflow-dev` | Workflow testing (static v6.x tag) | no |

The version in the branch name (`v<ver>`) must match a `versions/<ver>.env` file. See the root [README](../../README.md#build) for how `build.sh` resolves versions.

## Tag policy

Published release tags are immutable and match the Omada Software Controller version (e.g. `6.2.10.17`). Container-only rebuilds use a revision suffix (e.g. `6.2.10.17-r1`). `-dev` tags are replaceable and may be removed without notice. See the root README [Image Tag Policy](../../README.md#image-tag-policy) section.

## Concurrency

Superseded runs on the same branch are cancelled automatically. Tag (release) runs are never cancelled.
