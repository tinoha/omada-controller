#!/bin/bash

# Set up a trap to stop tpeap gracefully on termination signals
trap 'sudo /usr/bin/tpeap stop; exit $?' SIGTERM SIGINT

if [[ $# -eq 0 || ( "$1" == "tpeap" && "$2" == "start" ) ]]; then
    sudo /usr/bin/tpeap start
    rc=$? # Capture the start command exit code

    # Exit if tpeap failed to start
    if [[ "$rc" -ne 0 ]]; then
        exit "$rc"
    fi

    sleep infinity & # Keep the container running
    wait "$!" # Wait for the sleep process
else
    exec "$@"
fi
