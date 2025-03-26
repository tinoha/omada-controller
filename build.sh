#!/bin/bash

# Default Omada version
VER=""

# Print supported versions
print_supported_versions() {
  echo "Supported versions are:"
  echo "5.7.4"
  echo "5.12.7"
  echo "5.14.26"
  echo "5.15.20"
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

podman build --cap-add=DAC_READ_SEARCH,SETGID,SETUID,NET_BIND_SERVICE \
  --no-cache \
  --format docker \
  -t omada-controller:"${VER}" \
  -f "omada_v${VER}.Dockerfile" \
  --label org.opencontainers.image.authors="Tino <tinoha10@outlook.com>" \
  --label org.opencontainers.image.url="https://github.com/tinoha/omada-controller" \
  --label org.opencontainers.image.documentation="https://github.com/tinoha/omada-controller/blob/main/README.md" \
  --label org.opencontainers.image.version="${VER}" \
  --label org.opencontainers.image.created="$(date -u +'%Y-%m-%dT%H:%M:%SZ')" \
  --label org.opencontainers.image.revision="${COMMIT_HASH}" \
  .
