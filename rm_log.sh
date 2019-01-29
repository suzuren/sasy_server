#!/bin/sh

root_dir=$(cd `dirname $0`; pwd)

rm -rf logs program_log/*.log logs program_log/*.pid


cd ./luaclib-src
make clean
cd ${root_dir}


cd ./pbs
rm -rf *.pb
cd ${root_dir}


cd ./testsocket
make clean
cd ${root_dir}

cd ./chat_room
make clean
cd ${root_dir}

