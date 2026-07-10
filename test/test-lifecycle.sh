#!/bin/sh
# test-lifecycle.sh — full lifecycle test of the built image.
#
# Starts the container with no arguments (the default entrypoint path:
# entrypoint.sh runs `sudo tpeap start` + `sleep infinity & wait`), polls
# the logs for "Started successfully.", then asserts:
#   1. `sudo tpeap status` exits 0
#   2. /omada/healthcheck.sh exits 0 (the script Docker uses for HEALTHCHECK)
# Finally sends SIGTERM via `podman stop --time=200` to exercise the trap
# and graceful `tpeap stop`, then verifies "Stop successfully." in logs.
#
# This exercises entrypoint.sh, the SIGTERM trap, omada_sudoers, and
# healthcheck.sh — everything the smoke test does not cover.
#
# Usage: ./test-lifecycle.sh <tag>

set -eu

# shellcheck source=common.sh
. "$(dirname "$0")/common.sh"

TAG="${1:?usage: test-lifecycle.sh <tag>}"
image_exists "$TAG"
IMAGE="localhost/${IMAGE_NAME}:${TAG}"

# Start with no args — entrypoint runs tpeap start + sleep infinity.
ctr="omada-lifecycle-$$"
podman run -d --name "$ctr" "$IMAGE" >/dev/null
# shellcheck disable=SC2034 # used by common.sh cleanup trap
CONTAINERS="$ctr"

# Poll logs for startup (Omada takes 30-90s on a fresh container).
echo "Waiting for 'Started successfully.' (up to 120s)..."
log_poll "$ctr" "Started successfully." 120
if [ "$FOUND" -eq 1 ]; then
  pass "tpeap started"
else
  fail "timeout waiting for 'Started successfully.'"
  exit 1
fi

# Status check — tpeap status must exit 0.
if podman exec "$ctr" sudo tpeap status >/dev/null 2>&1; then
  pass "tpeap status"
else
  fail "tpeap status exited non-zero"
fi

# Healthcheck script — the same script Docker runs for HEALTHCHECK.
# Run it directly so we test the script itself, not Docker's polling.
if podman exec "$ctr" /omada/healthcheck.sh >/dev/null 2>&1; then
  pass "healthcheck.sh"
else
  fail "healthcheck.sh exited non-zero"
fi

# Graceful stop — sends SIGTERM, entrypoint trap runs tpeap stop.
echo "Stopping (graceful, up to 200s)..."
stop_and_verify "$ctr"

exit "$FAILED"
