

CPPFLAGS = -O3
LDFLAGS = -lrt -lpthread -lstdc++ -std=c++11

all: server client

clean:
	rm -f *.o *.pid server client

server: server.o
	g++ -o $@ $^ $(LDFLAGS)

client: client.o
	g++ -o $@ $^ $(LDFLAGS)

