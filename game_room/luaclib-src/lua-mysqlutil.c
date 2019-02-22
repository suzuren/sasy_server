#include <lua.h>
#include <lauxlib.h>
#include <stdint.h>
#include <string.h>
#include <ctype.h>
#include <stdlib.h>
#include "mysql.h"



static int escape_string (lua_State *L) {
  size_t size, new_size;
  const char *from = luaL_checklstring(L, 1, &size);
  char *to;
  to = (char*)malloc(sizeof(char) * (2 * size + 1));
  if(to) {
    new_size = mysql_escape_string(to, from, size);
    lua_pushlstring(L, to, new_size);
    free(to);
    return 1;
  }
  luaL_error(L, "could not allocate escaped string");
  return 0;
}

int luaopen_mysqlutil(lua_State *L) {
	luaL_checkversion(L);
	luaL_Reg l[] = {
		{ "escapestring", escape_string },
		{ NULL, NULL },
	};
	luaL_newlib(L,l);

	return 1;
}

