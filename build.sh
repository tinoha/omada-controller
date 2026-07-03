#!/bin/bash
# Build script for the Omada Controller container image.
#
# Usage: ./build.sh --set-ver <version> [--file <dockerfile>]
#
# --set-ver is always required. It is both the image-tag anchor and the key used
# to locate an optional version metadata file at versions/<version>.env.
#
# --file optionally overrides which Dockerfile is built. If omitted, the
# DOCKERFILE field from the env file is used. If neither is available the build
# errors out and asks the user to rerun with --file.
#
# Env file (shell-sourceable): two namespaces, distinguished by prefix:
#   BUILD_ARG_<NAME>="value"  -> forwarded to podman build as --build-arg <NAME>=value
#                                (prefix stripped; only these become build-args)
#   <NAME>="value"            -> consumed by build.sh only, never forwarded.
#                                e.g. DOCKERFILE selects which Dockerfile to build.
# There is no fixed allowlist or required-set: a future template that needs a
# new argument just adds a BUILD_ARG_<NAME> line to its env file and build.sh
# passes it through unchanged.
#
# Image tag: BUILD_ARG_OMADA_VER from the env file if set and non-empty,
# otherwise the --set-ver value.

# Default values for image metadata labels, which can be overridden by environment variables
IMAGE_URL="${IMAGE_URL:-https://github.com/tinoha/omada-controller}"
IMAGE_SOURCE="${IMAGE_SOURCE:-https://github.com/tinoha/omada-controller}"
IMAGE_DOCUMENTATION="${IMAGE_DOCUMENTATION:-https://github.com/tinoha/omada-controller/blob/main/README.md}"

VER=""
FILE_OPT=""

# Print supported versions (derived from versions/*.env so it cannot drift)
print_supported_versions() {
  echo "Supported versions are:"
  if [[ -d versions ]]; then
    for f in versions/*.env; do
      [[ -e "$f" ]] || continue
      basename "$f" .env
    done
  fi
}

# Argument handling
while [[ "$#" -gt 0 ]]; do
  case $1 in
  --set-ver)
    if [[ -n $2 ]]; then
      VER=$2
      shift
    else
      echo "Error: --set-ver requires a version argument." >&2
      exit 1
    fi
    ;;
  --file)
    if [[ -n $2 ]]; then
      FILE_OPT=$2
      shift
    else
      echo "Error: --file requires a path argument." >&2
      exit 1
    fi
    ;;
  --help)
    echo "Usage: $0 --set-ver <version> [--file <dockerfile>]"
    echo
    print_supported_versions
    echo
    echo "Versions without an env file can still be built by passing the"
    echo "Dockerfile explicitly, e.g.:"
    echo "  $0 --set-ver <version> --file <path>"
    exit 0
    ;;
  *)
    echo "Unknown option: $1" >&2
    echo "Use --help to see available options." >&2
    exit 1
    ;;
  esac
  shift
done

if [[ -z ${VER} ]]; then
  echo "No version set" >&2
  echo "Use --help to see available options." >&2
  exit 1
fi

# Locate and load the optional version metadata file
ENV_FILE="versions/${VER}.env"
ENV_KEYS=()
if [[ -f "${ENV_FILE}" ]]; then
  # Source for values (env files contain only assignments and comments)
  # shellcheck source=/dev/null
  . "${ENV_FILE}"
  # Parse assignment keys from the file text so we forward only keys the file
  # actually declares (not shell internals like PATH/HOME). Opt-in: a key must
  # start with BUILD_ARG_ to become a build-arg; the prefix is stripped so the
  # Dockerfile sees the unprefixed name (OMADA_VER, MONGO_VER, ...).
  while IFS= read -r line || [[ -n "$line" ]]; do
    [[ "$line" =~ ^[[:space:]]*# ]] && continue
    [[ -z "${line//[[:space:]]/}" ]] && continue
    if [[ "$line" =~ ^BUILD_ARG_([A-Za-z_][A-Za-z0-9_]*)= ]]; then
      ENV_KEYS+=("${BASH_REMATCH[1]}")
    fi
  done <"${ENV_FILE}"
fi

# Resolve which Dockerfile to build: --file overrides the env file's DOCKERFILE
if [[ -n "${FILE_OPT}" ]]; then
  DOCKERFILE="${FILE_OPT}"
elif [[ -n "${DOCKERFILE:-}" ]]; then
  : # from the env file
else
  echo "Error: no Dockerfile specified." >&2
  if [[ -f "${ENV_FILE}" ]]; then
    echo "Set DOCKERFILE in ${ENV_FILE} or rerun with --file <path>." >&2
  else
    echo "${ENV_FILE} was not found. Rerun with --file <path>, e.g.:" >&2
    echo "  $0 --set-ver ${VER} --file omada_v${VER}.Dockerfile" >&2
  fi
  exit 1
fi

if [[ ! -f "${DOCKERFILE}" ]]; then
  echo "Error: Dockerfile '${DOCKERFILE}' was not found." >&2
  exit 1
fi

# Image tag: prefer BUILD_ARG_OMADA_VER from the env file, fall back to --set-ver
if [[ -n "${BUILD_ARG_OMADA_VER:-}" ]]; then
  TAG="${BUILD_ARG_OMADA_VER}"
else
  TAG="${VER}"
fi

# Forward every BUILD_ARG_* key from the env file as a --build-arg (prefix
# stripped). Look up each value via its prefixed shell variable.
BUILD_ARGS=()
for name in "${ENV_KEYS[@]}"; do
  prefixed="BUILD_ARG_${name}"
  BUILD_ARGS+=(--build-arg "${name}=${!prefixed}")
done

echo "Omada Controller version: ${TAG}"
echo "Dockerfile: ${DOCKERFILE}"
echo ""
echo "Building omada-controller image for ${TAG} version..."

# v5.x installs via .deb, which starts the service during build and therefore
# needs elevated capabilities. v6.x uses the cluster-mode installer and needs none.
CAP_ARGS=()
if [[ "${TAG}" == 5.* ]]; then
  # shellcheck disable=SC2054 # comma-separated value is intentional for podman's --cap-add
  CAP_ARGS+=(--cap-add=DAC_READ_SEARCH,SETGID,SETUID,NET_BIND_SERVICE)
fi

# Commit hash for the image revision label
if [[ -n "${GITHUB_SHA:-}" ]]; then
  COMMIT_HASH="${GITHUB_SHA}"
else
  COMMIT_HASH="$(git rev-parse HEAD 2>/dev/null || echo "unknown")"
fi

podman build \
  "${BUILD_ARGS[@]}" \
  "${CAP_ARGS[@]}" \
  --format docker \
  -t omada-controller:"${TAG}" \
  -f "${DOCKERFILE}" \
  --label org.opencontainers.image.url="${IMAGE_URL}" \
  --label org.opencontainers.image.source="${IMAGE_SOURCE}" \
  --label org.opencontainers.image.documentation="${IMAGE_DOCUMENTATION}" \
  --label org.opencontainers.image.version="${TAG}" \
  --label org.opencontainers.image.created="$(date -u +'%Y-%m-%dT%H:%M:%SZ')" \
  --label org.opencontainers.image.revision="${COMMIT_HASH}" \
  .
