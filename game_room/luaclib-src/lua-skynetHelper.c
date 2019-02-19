#include <stdlib.h>
#include <stdint.h>
#include <ctype.h>
#include <lua.h>
#include <lauxlib.h>

static int l_free(lua_State *L) {
	if(!lua_islightuserdata(L, 1))
	{
		return luaL_error(L, "expect lightuserdata got %s", luaL_typename(L, 1));
	}
	void *ptr = lua_touserdata(L, 1);
	free(ptr);
	return 0;
}

int luaopen_skynetHelper(lua_State *L) {
	luaL_checkversion(L);
	luaL_Reg l[] = {
		{ "free", l_free },
		{ NULL, NULL },
	};
	luaL_newlib(L,l);

	return 1;
}


