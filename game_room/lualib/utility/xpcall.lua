local _errorMsg = nil

local function errorMessageSaver(errMsg)
	local co = coroutine.running()
	_errorMsg = string.format("%s\n%s", errMsg, debug.traceback(co, nil, 2))
end

local function getErrorMessage()
	local tmp = _errorMsg
	_errorMsg = nil
	return tmp
end

return {
	errorMessageSaver = errorMessageSaver,
	getErrorMessage = getErrorMessage,
}
