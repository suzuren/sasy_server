local skynet = require "skynet"
local xpcallUtility = require "utility.xpcall"

local _timerIDGenerator = 10
local _tick = 0
local _tickStep = 0
local _isTickerEnable = false
local _activeTimer = {}
local _exceptionHandler

local function doAddTimer(isInterval, func, interval, bindParameter)
	if type(func)~="function" then
		error("the 1st argument must be a function", 2)
	end
	
	if type(interval)~="number" or interval<0 then
		error("the 2nd argument must not be a negative number", 2)
	end
	
	if not _isTickerEnable then
		error(string.format("%s: timer is not active", SERVICE_NAME))
	end
	
	local item = {
		func = func,
		isInterval = isInterval,
		interval = interval,
		nextTick = _tick + interval,
	}
	if bindParameter~=nil then
		item.bindParameter = bindParameter
	end
	
	_timerIDGenerator = _timerIDGenerator+1
	_activeTimer[_timerIDGenerator] = item
	return _timerIDGenerator
end

local function setTimeout(func, delay, bindParameter)
	return doAddTimer(false, func, delay, bindParameter)
end

local function setInterval(func, interval, bindParameter)
	return doAddTimer(true, func, interval, bindParameter)
end

local function clearTimer(timerID)
	_activeTimer[timerID] = nil
end

local function ticker()
	while _tickStep > 0 do
		_tick = _tick + 1
		
		repeat
			local isFound = false
			for timerID, item in pairs(_activeTimer) do
				if item.nextTick <= _tick then
					isFound = true
					local isSuccess = xpcall(item.func, xpcallUtility.errorMessageSaver, item.bindParameter)
					if not isSuccess then
						skynet.error(string.format("%s: 执行定时器错误: %s", SERVICE_NAME, xpcallUtility.getErrorMessage()))
						
						if _exceptionHandler~=nil then
							_exceptionHandler()
						end
					end
					
					if item.isInterval then
						item.nextTick = _tick + item.interval
					else
						_activeTimer[timerID] = nil
					end
					break
				end
			end
		until not isFound
		
		if _tickStep > 0 then
			skynet.sleep(_tickStep)	
		end
	end
	_isTickerEnable = false
end

local function start(tickStep)
	if tickStep <= 0 then
		error("tickStep should greater than 0", 2)
	end
	
	_tickStep = tickStep
	if not _isTickerEnable then
		_isTickerEnable = true
		_tick = 0
		_activeTimer = {}		
		skynet.fork(ticker)
	end
end

local function stop()
	_tickStep = 0
	_tick = 0
	_activeTimer = {}
end

local function setExceptionHandler(handler)
	if type(handler)~="function" then
		error("exception handler must a function", 2)
	end
	_exceptionHandler = handler
end

return {
	setTimeout = setTimeout,
	setInterval = setInterval,
	clearTimer = clearTimer,
	setExceptionHandler = setExceptionHandler,
	start = start,
	stop = stop,
}
