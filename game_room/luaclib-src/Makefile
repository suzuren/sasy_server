CC = gcc
CFLAGS = -O2 -fPIC -Wall
LUA_INC = ../../skynet/3rd/lua/
SKYNET_DIR = ../../skynet/
SKYNET_INC = ../../skynet/skynet-src/
SKYNET_SIC = ../../skynet/service-src/
#SKYNET_LUA_CLIB_PATH = ../skynet/luaclib/
MYSQL_INC = /usr/include/mysql/

.PHONY : all clean

all : protobuf.so pbcc.so skynetHelper.so sui.so mysqlutil.so

protobuf.so : pbc-lua53.c
	cd lua-cjson && make
	cp lua-cjson/cjson.so cjson.so
	cd pbc && make
	$(CC) $(CFLAGS) -shared -o $@ -I./pbc -I$(LUA_INC) -L./pbc/build $^ -lpbc

pbcc.so : lua-pbcc.c
	gcc -g -O2 -Wall -I$(LUA_INC) -I$(SKYNET_INC) -fPIC --shared $^ -o $@

skynetHelper.so : lua-skynetHelper.c
	gcc -g -O2 -Wall -I$(LUA_INC)  -fPIC --shared $^ -o $@

sui.so : lua-sui.c
	gcc -g -O2 -Wall -I$(LUA_INC)  -fPIC --shared $^ -o $@

mysqlutil.so : lua-mysqlutil.c
	gcc -g -O2 -Wall -I$(LUA_INC) -I$(MYSQL_INC)  -fPIC --shared $^ -o $@

#socketdriver.so : $(SKYNET_DIR)lualib-src/lua-socket.c | $(SKYNET_LUA_CLIB_PATH)
	#gcc -g -O2 -Wall -fPIC --shared $^ -o $@ -I$(SKYNET_INC) -I$(SKYNET_SIC) -I$(LUA_INC)
	#mkdir skynet && mv socketdriver.so skynet/socketdriver.so

clean :
	cd lua-cjson && make clean
	cd pbc && make clean
	rm -f *.so
