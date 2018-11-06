local skynet = require "skynet"

local function d(lev, ...)
	if  ... == nil then
		if type(lev) == "table" then
			skynet.send(".xLogService", "lua", "xLog", "DEBUG", serialize(lev))
		else
			skynet.send(".xLogService", "lua", "xLog", "DEBUG", ""..lev)
		end
	else
		if type(...) == "table" then
			skynet.send(".xLogService", "lua", "xLog", "DEBUG", ""..lev..serialize(...))
		else
			local logStr = ...
			skynet.send(".xLogService", "lua", "xLog", lev, ""..logStr)
		end
	end
end

function serialize(t)
	local mark={}
	local assign={}
	
	local function ser_table(tbl,parent)
		mark[tbl]=parent
		local tmp={}
		for k,v in pairs(tbl) do
			local key= type(k)=="number" and "["..k.."]" or k
			if type(v)=="table" then
				local dotkey= parent..(type(k)=="number" and key or "."..key)
				if mark[v] then
					table.insert(assign,dotkey.."="..mark[v])
				else
					table.insert(tmp, key.."="..ser_table(v,dotkey))
				end
			elseif type(v)=="boolean" then
				if v then
					table.insert(tmp, key.."=true")
				else
					table.insert(tmp, key.."=false")
				end
			else
				table.insert(tmp, key.."="..v)
			end
		end
		return "{"..table.concat(tmp,",").."}"
	end
 
	return ser_table(t,"ret")..table.concat(assign," ")
end

return d