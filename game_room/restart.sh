#!/bin/sh
./stop.sh
sleep 1
ulimit -c unlimited
ulimit -a
../skynet/skynet config/config.login
