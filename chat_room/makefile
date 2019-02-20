CPPFLAGS = -O3
LDFLAGS = -lrt -lpthread -lstdc++ -std=c++11

LUA_INC := ../skynet/3rd/lua


all: exeClient ./lualib-src/parsedata.so ./lualib-src/skynet_socketdriver.so

./lualib-src/parsedata.so : ./lualib-src/lua-parsedata.c
	gcc -g -O2 -Wall -lrt -I$(LUA_INC) -Ilualib-src -fPIC --shared $^ -o $@


./lualib-src/skynet_socketdriver.so : ./lualib-src/lua-socket.c
	gcc -g -O2 -Wall -I../skynet/3rd/lua -fPIC --shared $^ -o $@ -I../skynet/skynet-src

exeClient : ./client/client.o
	gcc -lpthread ./client/client.o -o ./client/exeClient -Iclient


./client/client.o : ./client/client.c
	gcc  -g -Wall -c ./client/client.c -o ./client/client.o -I./lualib-src

clean:
	rm -rf ./lualib-src/*.so ./client/*.o *.pid ./client/exeClient core.* ./client/core.*
