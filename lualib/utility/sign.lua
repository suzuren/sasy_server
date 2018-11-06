local arc4 = require "arc4random"

local function getSign()
	local str = arc4.buf( 16 )
	str = str:gsub( "(.)", function( c )
		return string.format("%02x", string.byte(c))
	end )
	return str
end

return {
	getSign = getSign,
}

