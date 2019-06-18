#!/bin/sh
ulimit -c unlimited
ulimit -a
../skynet/skynet ./http_config
