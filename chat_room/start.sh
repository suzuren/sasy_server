#!/bin/sh
ulimit -c unlimited
ulimit -a
../skynet/skynet ./service/chat_config
