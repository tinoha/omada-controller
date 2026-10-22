#!/bin/bash

# Set up a trap to stop tpeap gracefully on termination signals
trap 'sudo /usr/bin/tpeap stop; exit $?' SIGTERM SIGINT

if [[ $# -eq 0 || ("$1" == "tpeap" && "$2" == "start") ]]; then
  # /var/run survives container restarts (it is part of the writable layer), so
  # a PID file from the previous run can name an unrelated process that is
  # alive in the new PID namespace. jsvc then refuses to start ("Still running
  # according to PID file") and Omada never comes up. Nothing from a previous
  # run can still be alive here, so drop any leftover PID file.
  sudo /usr/bin/rm -f /var/run/omada.pid
  sudo /usr/bin/tpeap start
  rc=$? # Capture the start command exit code

  # Exit if tpeap failed to start
  if [[ "$rc" -ne 0 ]]; then
    exit "$rc"
  fi

  sleep infinity & # Keep the container running
  wait "$!"        # Wait for the sleep process
else
  exec "$@"
fi
