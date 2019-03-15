#!/bin/sh

root_dir=$(cd `dirname $0`; pwd)
echo "root_dir:" ${root_dir}
echo ""
rm -rf ./project/Debug/ ./project/x64/ ./project/.vs ./project/project.opensdf ./project/project.sdf ./project/project.VC.db

cd ./game_room/
make clean
cd ${root_dir}

cd ./testsocket
make clean
cd ${root_dir}

cd ./chat_room
make clean
cd ${root_dir}

