#!/bin/bash

# Set available Omada version
# VER="";
# VER="5.7.4"
VER="5.12.7"

if [[ -z ${VER} ]]; then
  echo "Edit script and set version (VER)"
  exit 1
fi

echo "Building ${VER} version..."
echo ""

podman build --cap-add=DAC_READ_SEARCH,SETGID,SETUID,NET_BIND_SERVICE \
  --no-cache \
  --format docker \
  -t docker.io/tihal/omada-controller:"${VER}" \
  -f "omada_v${VER}.Dockerfile" \
  --label org.opencontainers.image.authors="Tino <tinoha10@outlook.com>" \
  --label org.opencontainers.image.url="https://github.com/tinoha/omada-controller" \
  --label org.opencontainers.image.documentation="https://github.com/tinoha/omada-controller/blob/main/README.md" \
  --label org.opencontainers.image.version="${VER}" \
  --label org.opencontainers.image.created="$(date -u +'%Y-%m-%dT%H:%M:%SZ')" \
  --label org.opencontainers.image.revision="$(git log main -1 --format=%h)" \
  .
