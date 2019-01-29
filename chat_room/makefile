CPPFLAGS = -O3
LDFLAGS = -lrt -lpthread -lstdc++ -std=c++11

LUA_INC := /usr/local/lua/include


all: exeClient ./lualib-src/parsedata.so

./lualib-src/parsedata.so : ./lualib-src/lua-parsedata.c
	gcc -g -O2 -Wall -lrt -I$(LUA_INC) -Ilualib-src -fPIC --shared $^ -o $@



exeClient : ./client/client.o
	gcc ./client/client.o -o ./client/exeClient -Iclient


./client/client.o : ./client/client.c
	gcc -g -Wall -c ./client/client.c -o ./client/client.o -I./lualib-src

clean:
	rm -rf ./lualib-src/*.so ./client/*.o *.pid ./client/exeClient
