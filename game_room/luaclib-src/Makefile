CC = gcc
CFLAGS = -O2 -fPIC -Wall
LUA_INC = ../../skynet/3rd/lua/
SKYNET_DIR = ../../skynet/
SKYNET_INC = ../../skynet/skynet-src/
SKYNET_SIC = ../../skynet/service-src/
SKYNET_LIB = ../../skynet/lualib-src/
#SKYNET_LUA_CLIB_PATH = ../skynet/luaclib/
MYSQL_INC = /usr/include/mysql/

.PHONY : all clean

all : depend protobuf.so pbcc.so skynetHelper.so sui.so memory.so mysqlutil.so websocketnetpack.so

depend :
	cd lua-arc4random && make
	cp lua-arc4random/arc4random.so arc4random.so
	cd pbc && make

protobuf.so : pbc-lua53.c
	cd lua-cjson && make
	cp lua-cjson/cjson.so cjson.so
	$(CC) $(CFLAGS) -shared -o $@ -I./pbc -I$(LUA_INC) -L./pbc/build $^ -lpbc

pbcc.so : lua-pbcc.c
	gcc -g -O2 -Wall -I$(LUA_INC) -I$(SKYNET_INC) -fPIC --shared $^ -o $@

skynetHelper.so : lua-skynetHelper.c
	gcc -g -O2 -Wall -I$(LUA_INC) -I$(SKYNET_INC)  -fPIC --shared $^ -o $@

sui.so : lua-sui.c
	gcc -g -O2 -Wall -I$(LUA_INC)  -fPIC --shared $^ -o $@

memory.so : $(SKYNET_LIB)/lua-memory.c
	gcc -g -O2 -Wall -I$(LUA_INC) -I$(SKYNET_LIB) -I$(SKYNET_INC) -fPIC --shared $^ -o $@

mysqlutil.so : lua-mysqlutil.c
	#gcc -g -O2 -Wall -lpthread -I$(LUA_INC) -I$(SKYNET_INC) -I$(MYSQL_INC)  -fPIC --shared $^ -o $@ -L/usr/lib64/mysql -lmysqlclient

websocketnetpack.so : lua-websocketnetpack.c
	gcc -g -O2 -Wall -I$(LUA_INC) -fPIC --shared -I$(SKYNET_INC) $^ -o $@
	
clean :
	cd lua-cjson && make clean
	cd lua-arc4random && make clean
	cd pbc && make clean
	rm -f *.so
