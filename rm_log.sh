#!/bin/sh

root_dir=$(cd `dirname $0`; pwd)

rm -rf ./game_room/logs ./game_room/program_log/*.log ./game_room/program_log/*.pid

cd ./game_room/luaclib-src
make clean
cd ${root_dir}


cd ./game_room/pbs
rm -rf *.pb
cd ${root_dir}


cd ./testsocket
make clean
cd ${root_dir}

cd ./chat_room
make clean
cd ${root_dir}

