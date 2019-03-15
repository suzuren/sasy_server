#!/bin/sh

root_dir=$(cd `dirname $0`; pwd)

cd ./game_room/
make clean
cd ${root_dir}

cd ./testsocket
make clean
cd ${root_dir}

cd ./chat_room
make clean
cd ${root_dir}

