
local _user_lib_mysqlclient = false


local luamysql = null

if _user_lib_mysqlclient then
	luamysql = require "mysqlutil"
else
	luamysql = require "skynet.db.mysql"
end

function escapestring(str)
	if _user_lib_mysqlclient then
		return luamysql.escapestring(str)
	else
		return luamysql.quote_sql_str(str)
	end
end

return{
	escapestring = escapestring,
}

