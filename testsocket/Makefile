

CPPFLAGS = -O3
LDFLAGS = -lrt -lpthread -lstdc++ -std=c++11

LUA_INC := /usr/local/lua/include


all: server client parsedata.so

parsedata.so : lua-parsedata.c
	gcc -g -O2 -Wall -lrt -I$(LUA_INC) -fPIC --shared $^ -o $@

server: server.o
	g++ -o $@ $^ $(LDFLAGS)

client: client.o
	g++ -o $@ $^ $(LDFLAGS)


clean:
	rm -rf *.so *.o *.pid server client
