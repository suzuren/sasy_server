local function makeTimeStamp(dateString)
	local pattern = "(%d+)-(%d+)-(%d+) (%d+):(%d+):(%d+)"
	local year, month, day, hour, minute, second = dateString:match(pattern)
	if year==nil then
		error("invalid format")
	end
	
	local data = {
		['year'] = tonumber(year),
		['month'] = tonumber(month),
		['day'] = tonumber(day),
		['hour'] = tonumber(hour),
		['min'] = tonumber(minute),
		['sec'] = tonumber(second),
		['isdst'] = false,
	}
	return os.time(data)
end

return {
	makeTimeStamp = makeTimeStamp,
}