#include "skynet_malloc.h"

#include <lua.h>
#include <lauxlib.h>
#include <stdint.h>
#include <string.h>


// prt does not contain the 2 bytes big-endian network packet header
static int l_unpackNetPayload(lua_State *L) {
	char *ptr;
	int size;
	//int test = 0;
	if (lua_type(L,1) == LUA_TSTRING) {
		//test=1;
		ptr = (char *)luaL_checklstring(L,1,(size_t *)&size);
	} else {
		//test=2;
		ptr = (char *)lua_touserdata(L, 1);
		size = luaL_checkinteger(L, 2);
	}
	
	if( size < 3 )
	{
		return luaL_error(L, "parse protobuf packet failed, invalid format");
	}
	//int i=1;
	int k = 0;
	
	int pbNo = ( (unsigned char)ptr[1] << 16 ) | ( (unsigned char)ptr[2] << 8 ) | (unsigned char)ptr[3];
	
	
	lua_pushinteger(
		L, pbNo
	);
	
	lua_pushlstring(L,ptr+4,size-4);
	lua_pushinteger(L,k);
	lua_pushinteger(L,(unsigned char)ptr[0]);
	return 4;
}

/**
 * return network packet in buffer for socket.write.
 * @param uint8_t* ptr
 * @param int size
 * @param int protoNo
 */
static int l_packNetPBPacket(lua_State *L) {

	if(!lua_islightuserdata(L, 1))
	{
		return luaL_error(L, "expect lightuserdata got %s", luaL_typename(L, 1));
	}
	uint8_t *ptr = (uint8_t*)lua_touserdata(L, 1);
	
	int size = luaL_checkinteger(L, 2);
	if(size >= 0x10000 )
	{
		return luaL_error(L, "message length(%d) exceed the upper limit", size);
	}
	
	lua_Unsigned protoNo = (lua_Unsigned)luaL_checkinteger(L, 3);
	int test = lua_toboolean(L, 4);
	
	uint8_t *buffer = skynet_malloc(size+6);
	if (size > 0)
	{
		memcpy(buffer+6, ptr, size);
	}
	
	size += 4;			// actual network payload size
	buffer[0] = (size >> 8) & 0xff;
	buffer[1] = size & 0xff;
	buffer[2] = 0;
	buffer[3] = (protoNo >> 16) & 0xff;
	buffer[4] = (protoNo >> 8) & 0xff;
	buffer[5] = protoNo & 0xff;
	int i=0;
	int k = 0;
	for(i=3;i<size+2;i++)
	{
		k+=((unsigned char)buffer[i]);
		k&=0xff;
	}
	if(!test)
	{
		lua_pushlightuserdata(L, buffer);
		lua_pushinteger(L, size+2);
	}
	else
	{
		lua_pushlstring(L, (char *)buffer, size + 2);
		lua_pushinteger(L, size + 2);
		skynet_free(buffer);
	}
	return 2;
}

int luaopen_pbcc(lua_State *L) {
	luaL_checkversion(L);
	luaL_Reg l[] = {
		{ "unpackNetPayload", l_unpackNetPayload },
		{ "packNetPacket", l_packNetPBPacket },
		{ NULL, NULL },
	};
	luaL_newlib(L,l);

	return 1;
}

