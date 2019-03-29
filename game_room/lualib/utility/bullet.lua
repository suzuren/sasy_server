local randHandle = require "utility.randNumber"

local _minMultiple, _maxMultiple
local _upLimit = {}


local _chairPerTable = 0
local _fireAngleArray = {}
local _lastAngle = 0
local _multipleThreshold = {}

local function setMultipleLimit(min, max)
	_minMultiple, _maxMultiple = min, max
	
	for i=0, 3 do
		local upLimit = _minMultiple * 100 * (10 ^ i)
		if upLimit > _maxMultiple then
			upLimit = _maxMultiple
		end
		
		_upLimit[i] = upLimit
		if upLimit >= _maxMultiple then
			break
		end
	end
end

local function getBulletKindByScore(score)
	local bulletKind = 0
	for i=0, 3 do
		local upLimit = _upLimit[i]
		if upLimit==nil then
			break
		end
		
		bulletKind = i
		
		if score < upLimit then
			break
		end
	end
	
	return bulletKind
end

local function getBulletBaseByKind(bulletKind)
	if bulletKind < 0 or bulletKind > 3 then
		error(string.format("%s bulletUtility.getBulletBaseByKind invalid bulletKind: %s", SERVICE_NAME, tostring(bulletKind)))
	end
	
	return _minMultiple * (10 ^ bulletKind) 
end

local function getBulletMultipleByKind(score, bulletKind)
	local baseScore = getBulletBaseByKind(bulletKind)
	local maxMultiplier = math.floor(score/baseScore)
	
	local multiplier
	if maxMultiplier > _multipleThreshold.big then
		local r = randHandle.random(1, 2)
		if r==1 then
			multiplier = 2
		else
			multiplier = 5
		end
	elseif maxMultiplier > _multipleThreshold.middle then
		multiplier = randHandle.random(1, 2)
	else
		multiplier = 1
	end
	
	return baseScore * multiplier
end

local function setChairPerTable(n)
	_chairPerTable = n
	
	local angleArray = {}
	for i=-12,12 do
		table.insert(angleArray, i*5)
	end
	_fireAngleArray = angleArray
	
	_multipleThreshold = {
		big = randHandle.random(240, 320),
		middle = randHandle.random(80, 120),
	}
end

local function getAngle(chairID)
	local idx = 1
	for i, angle in ipairs(_fireAngleArray) do
		if angle==_lastAngle then
			idx = i
			break
		end
	end
	
	local arrayLength = #(_fireAngleArray)
	idx = idx + randHandle.random(-4, 4)
	
	if idx < 1 or idx > arrayLength then
		idx = randHandle.random(1, arrayLength)
	end
	
	local angle = _fireAngleArray[idx]
	if _chairPerTable==4 then
		if chairID==3 or chairID==4 then
			angle = angle + 180
		end
	else
		if chairID==4 or chairID==5 or chairID==6 then
			angle = angle + 180
		end
	end
	
	_lastAngle = angle
	
	return angle
end

return {
	setMultipleLimit = setMultipleLimit,
	getBulletKindByScore = getBulletKindByScore,
	getBulletBaseByKind = getBulletBaseByKind,
	getBulletMultipleByKind = getBulletMultipleByKind,
	setChairPerTable = setChairPerTable,
	getAngle = getAngle,
}
