#!/bin/sh
# test-smoke.sh — quick smoke test of the built image.
#
# Starts a container with a simple keep-alive command (tail -f /dev/null),
# then runs `sudo tpeap start` and `sudo tpeap stop` via podman exec to
# confirm both commands work and produce the expected output. This
# exercises the tpeap commands and omada_sudoers rules, but NOT the
# entrypoint's no-args path or the SIGTERM trap (see test-lifecycle.sh
# for that).
#
# Usage: ./test-smoke.sh <tag>

set -eu

# shellcheck source=common.sh
. "$(dirname "$0")/common.sh"

TAG="${1:?usage: test-smoke.sh <tag>}"
image_exists "$TAG"
IMAGE="localhost/${IMAGE_NAME}:${TAG}"

# Start container with a keep-alive command so it stays running.
ctr="omada-smoke-$$"
podman run -d --name "$ctr" "$IMAGE" tail -f /dev/null >/dev/null
# shellcheck disable=SC2034 # used by common.sh cleanup trap
CONTAINERS="$ctr"

# Start tpeap and check the startup message.
start_output=$(podman exec "$ctr" sudo tpeap start 2>&1)
echo "$start_output"
if printf '%s' "$start_output" | grep -qF "Started successfully."; then
  pass "tpeap started"
else
  fail "expected 'Started successfully.' in output"
  exit 1
fi

# Stop tpeap and check the shutdown message.
stop_output=$(podman exec "$ctr" sudo tpeap stop 2>&1)
echo "$stop_output"
if printf '%s' "$stop_output" | grep -qF "Stop successfully."; then
  pass "tpeap stopped"
else
  fail "expected 'Stop successfully.' in output"
fi

exit "$FAILED"
