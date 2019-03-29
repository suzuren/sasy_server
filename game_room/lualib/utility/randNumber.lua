
local _user_math_rand = false


local _randHandle = null

if _user_math_rand then
	_randHandle = math
else
	_randHandle = require "arc4random"
end

math.randomseed(os.time())

return _randHandle

