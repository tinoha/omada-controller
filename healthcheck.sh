#!/bin/sh

# Run the health check command and check for the expected output
sudo /usr/bin/tpeap status | /usr/bin/grep -qF \
 -e "Omada Controller is running." \
 -e "Omada Network Application is running."

# Return the exit code of the health check command
exit $?
