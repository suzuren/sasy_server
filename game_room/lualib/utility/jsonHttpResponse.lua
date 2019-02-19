local cjson = require "cjson"

local function getResponse(jsonObj)
	return 200, cjson.encode(jsonObj), {["Content-type"] = "application/json"}
end

local function getSimpleResponse(isSuccess, errorMsg)
	local jsonObj = {["isSuccess"]=isSuccess}
	if errorMsg ~= nil then
		jsonObj["error"] = errorMsg;
	end
	
	return getResponse(jsonObj)
end

return {
	getResponse = getResponse,
	getSimpleResponse = getSimpleResponse,
}
