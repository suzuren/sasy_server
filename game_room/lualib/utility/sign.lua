local randHandle = require "utility.randNumber"

local function getSign()
	local str = randHandle.buf( 16 )
	str = str:gsub( "(.)", function( c )
		return string.format("%02x", string.byte(c))
	end )
	return str
end

return {
	getSign = getSign,
}

