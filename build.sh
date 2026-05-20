#!/bin/bash
# Build script for the Omada Controller Docker image.

# Set default values for image metadata labels, which can be overridden by environment variables
IMAGE_URL="${IMAGE_URL:-https://github.com/tinoha/omada-controller}"
IMAGE_SOURCE="${IMAGE_SOURCE:-https://github.com/tinoha/omada-controller}"
IMAGE_DOCUMENTATION="${IMAGE_DOCUMENTATION:-https://github.com/tinoha/omada-controller/blob/main/README.md}"


# Default Omada version
VER=""

# Print supported versions
print_supported_versions() {
  echo "Supported versions are:"
  echo "5.7.4"
  echo "5.12.7"
  echo "5.14.26"
  echo "5.15.20"
  echo "5.15.20.18"
  echo "5.15.24.17"
  echo "5.15.24.18"
  echo "6.0.0.24"
  echo "6.0.0.25"
  echo "6.1.0.19"
  echo "6.2.0.17"
  echo "6.2.10.17"
}

# Argument handling
while [[ "$#" -gt 0 ]]; do
  case $1 in
    --set-ver)
      if [[ -n $2 ]]; then
        VER=$2
        shift
      else
        echo "Error: --set-ver requires a version argument."
        exit 1
      fi
      ;;
    --help)
      echo "Usage: $0 [--set-ver <version>]"
      print_supported_versions
      exit 0
      ;;
    *)
      echo "Unknown option: $1"
      echo "Use --help to see available options."
      exit 1
      ;;
  esac
  shift
done

# Check if VER is set
if [[ -z ${VER} ]]; then
  echo "No version set"
  echo "Use --help to see available options."
  exit 1
fi

# Check Dockerfile for VER exists
if [[ ! (-f "./omada_v${VER}.Dockerfile") ]]; then
  echo "File ./omada_v${VER}.Dockerfile was not found" 
  echo "Use --help to see available options."
  exit 1
fi

# Continue script execution with VER
echo "Used Omada version: ${VER}"

echo "Building image omada-controller for ${VER} version..."
echo ""

# Check if GITHUB_SHA is set (indicating that the script is running in GitHub Actions)
if [[ -n "${GITHUB_SHA}" ]]; then
  COMMIT_HASH="${GITHUB_SHA}"
else
  # For local runs get the hash from git.
  COMMIT_HASH="$(git log main -1 --format=%h)"
fi

# Build the image with the specified version and labels
# Use additional build arguments for v5.x images
if [[ "${VER}" == 5.* ]]; then
  BUILD_ARGS+=(--cap-add=DAC_READ_SEARCH,SETGID,SETUID,NET_BIND_SERVICE)
else
  BUILD_ARGS=()
fi

podman build \
  "${BUILD_ARGS[@]}" \
  --format docker \
  -t omada-controller:"${VER}" \
  -f "omada_v${VER}.Dockerfile" \
  --label org.opencontainers.image.url="${IMAGE_URL}" \
  --label org.opencontainers.image.source="${IMAGE_SOURCE}" \
  --label org.opencontainers.image.documentation="${IMAGE_DOCUMENTATION}" \
  --label org.opencontainers.image.version="${VER}" \
  --label org.opencontainers.image.created="$(date -u +'%Y-%m-%dT%H:%M:%SZ')" \
  --label org.opencontainers.image.revision="${COMMIT_HASH}" \
  .
