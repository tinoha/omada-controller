#!/bin/bash

APP="sudo /usr/bin/tpeap" 

trap '$APP stop' SIGTERM SIGINT

if [ "$1" == "tpeap" ] && [ "$2" == "start" ] || [ $# == 0 ]; then
    $APP start
    if [ $? != 0 ]; then exit $?; fi
    sleep infinity &
    wait
fi

$@