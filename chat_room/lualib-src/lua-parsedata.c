
#include <lua.h>
#include <lauxlib.h>
#include <stdlib.h>
#include <stdint.h>
#include <assert.h>
#include <string.h>
#include <stdio.h>


#include "packetmacro.h"

#define skynet_malloc malloc
#define skynet_free   free


static size_t
count_size(lua_State *L, int index) {
	size_t tlen = 0;
	int i;
	for (i=1;lua_geti(L, index, i) != LUA_TNIL; ++i) {
		size_t len;
		luaL_checklstring(L, -1, &len);
		tlen += len;
		lua_pop(L,1);
	}
	lua_pop(L,1);
	return tlen;
}

static void
concat_table(lua_State *L, int index, void *buffer, size_t tlen) {
	char *ptr = buffer;
	int i;
	for (i=1;lua_geti(L, index, i) != LUA_TNIL; ++i) {
		size_t len;
		const char * str = lua_tolstring(L, -1, &len);
		if (str == NULL || tlen < len) {
			break;
		}
		memcpy(ptr, str, len);
		ptr += len;
		tlen -= len;
		lua_pop(L,1);
	}
	if (tlen != 0) {
		skynet_free(buffer);
		luaL_error(L, "Invalid strings table");
	}
	lua_pop(L,1);
}

void *
get_buffer(lua_State *L, int index, int *sz) {
	void *buffer;
	switch(lua_type(L, index)) {
		const char * str;
		size_t len;
	case LUA_TUSERDATA:
	case LUA_TLIGHTUSERDATA:
		buffer = lua_touserdata(L,index);
		*sz = luaL_checkinteger(L,index+1);
		break;
	case LUA_TTABLE:
		// concat the table as a string
		len = count_size(L, index);
		buffer = skynet_malloc(len);
		concat_table(L, index, buffer, len);
		*sz = (int)len;
		break;
	default:
		str =  luaL_checklstring(L, index, &len);
		buffer = skynet_malloc(len);
		memcpy(buffer, str, len);
		*sz = (int)len;
		break;
	}
	return buffer;
}

static int
l_parsepacket(lua_State *L) {
	int id = luaL_checkinteger(L, 1);
	int sz = 0;
	//void *buffer = get_buffer(L, 2, &sz);
	size_t size;
	const char * buffer = luaL_checklstring(L, 2, &size);
	sz = (int)size;
	int err = 0;
	int len = 0;
	if(sz >= sizeof(struct packet_header))
	{
		struct packet_data * pdata = (struct packet_data *)buffer;
		len = sizeof(struct packet_header) + pdata->header.len;
		if(sz >= len)
		{
			err = 1;
		}
	}

	lua_pushinteger(L, err);
    lua_pushinteger(L, id);
    lua_pushinteger(L, sz);
    lua_pushlstring(L, buffer, len);
    lua_pushinteger(L, sz-len);
	lua_pushlstring(L, buffer+sz, sz-len);

	return 6;
}



int luaopen_parsedata(lua_State *L) {
	luaL_checkversion(L);
	
	luaL_Reg l[] = {
		{ "parsepacket", l_parsepacket },
		{ NULL, NULL },
	};
	luaL_newlib(L,l);

	return 1;
}