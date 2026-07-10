#!/bin/bash
# run.sh — entrypoint for the test/ harness.
#
# Usage: ./test/run.sh --tag <ver> --suite smoke|lifecycle
#
# The image must already be built (./build.sh --set-ver <ver>). v6.x only;
# v5.x is legacy and refused. v6.x needs no extra capabilities at runtime.

set -eu

usage() {
  cat <<EOF
Usage: $0 --tag <version> --suite smoke|lifecycle

  --tag     Image tag to test (e.g. 6.2.10.17). Image must be built already.
  --suite   Which suite to run:
              smoke       — tpeap start/stop via direct commands (~1min)
              lifecycle   — full container lifecycle: no-args entrypoint,
                            tpeap status, healthcheck.sh, graceful stop (~2-3min)
  --help    This message.

The image must already exist: run ./build.sh --set-ver <tag> first.
EOF
}

TAG=""
SUITE=""

while [ "$#" -gt 0 ]; do
  case "$1" in
  --tag)
    TAG="$2"
    shift 2
    ;;
  --suite)
    SUITE="$2"
    shift 2
    ;;
  --help)
    usage
    exit 0
    ;;
  *)
    echo "unknown option: $1" >&2
    usage >&2
    exit 1
    ;;
  esac
done

[ -n "$TAG" ] || {
  usage >&2
  exit 1
}
[ -n "$SUITE" ] || {
  usage >&2
  exit 1
}

# v5.x is legacy — not tested.
case "$TAG" in
5.*)
  echo "v5.x is legacy, not tested. See AGENTS.md." >&2
  exit 1
  ;;
esac

DIR="$(cd "$(dirname "$0")" && pwd)"

echo "--- suite: $SUITE (tag $TAG) ---"
if "$DIR/test-${SUITE}.sh" "$TAG"; then
  echo "--- suite: $SUITE PASSED ---"
  exit 0
else
  echo "--- suite: $SUITE FAILED ---"
  exit 1
fi
