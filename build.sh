podman build --cap-add=DAC_READ_SEARCH,SETGID,SETUID,NET_BIND_SERVICE \
  --no-cache \
  --format docker \
  -t docker.io/tihal/omada-controller:5.7.4 \
  -f Dockerfile \
  --label org.opencontainers.image.authors="Tino <tinoha10@outlook.com>" \
  --label org.opencontainers.image.url="https://github.com/tinoha/omada-controller" \
  --label org.opencontainers.image.documentation="https://github.com/tinoha/omada-controller/blob/main/README.md" \
  --label org.opencontainers.image.version="5.7.4" \
  --label org.opencontainers.image.created="$(date -u +'%Y-%m-%dT%H:%M:%SZ')" \
  --label org.opencontainers.image.revision="$(git log main -1 --format=%h)" \

