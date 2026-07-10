#!/bin/sh
# shellcheck shell=dash
# common.sh — shared helpers for test-*.sh scripts.
#
# Sourced by test-smoke.sh and test-lifecycle.sh. Provides:
#   - image_exists:  check the image is present locally
#   - log_poll:      poll container logs for a string within a timeout
#   - stop_and_verify: graceful stop + verify shutdown message in logs
#   - pass/fail:     print result lines and track overall status
#   - cleanup trap:  remove containers created during the test run
#
# shellcheck disable=SC2034 # FAILED, FOUND, CONTAINERS are used by callers via sourcing.

IMAGE_NAME="${IMAGE_NAME:-omada-controller}"
FAILED=0
CONTAINERS=""

# cleanup — remove any containers we started. Sourced scripts inherit this trap.
_cleanup() {
  for c in $CONTAINERS; do
    podman rm -f "$c" >/dev/null 2>&1 || true
  done
}
trap _cleanup EXIT INT TERM

pass() { echo "PASS: $1"; }
fail() {
  echo "FAIL: $1" >&2
  FAILED=1
}

# image_exists <tag> — exit 1 if the image is not found locally.
image_exists() {
  tag="$1"
  if ! podman image inspect "localhost/${IMAGE_NAME}:${tag}" >/dev/null 2>&1; then
    echo "Image localhost/${IMAGE_NAME}:${tag} not found." >&2
    echo "Build it first: ./build.sh --set-ver ${tag}" >&2
    exit 1
  fi
}

# log_poll <container> <pattern> <timeout_seconds>
# Polls `podman logs` every 2s for the pattern. Sets global FOUND=1 on hit.
log_poll() {
  ctr="$1"
  pattern="$2"
  timeout="$3"
  deadline=$(($(date +%s) + timeout))
  FOUND=0
  while [ "$(date +%s)" -lt "$deadline" ]; do
    if podman logs "$ctr" 2>&1 | grep -qF "$pattern"; then
      FOUND=1
      return
    fi
    sleep 2
  done
}

# stop_and_verify <container>
# Sends SIGTERM via podman stop (200s grace period), then
# checks logs for "Stop successfully." Reports pass/fail.
stop_and_verify() {
  ctr="$1"
  podman stop --time=200 "$ctr" >/dev/null
  if podman logs "$ctr" 2>&1 | grep -qF "Stop successfully."; then
    pass "tpeap stopped gracefully"
  else
    fail "expected 'Stop successfully.' in logs"
  fi
}
