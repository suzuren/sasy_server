#!/bin/sh
cat ./program_log/loginserver.pid | xargs kill
cat ./program_log/gameserver.pid | xargs kill
