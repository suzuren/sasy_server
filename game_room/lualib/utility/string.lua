function string:split(delimiter)
	local args = {}
	local pattern = '(.-)' .. delimiter
	local last_end = 1
	local s,e,cap = self:find(pattern, 1)
	while s do
		if s ~= 1 or cap ~= '' then
			table.insert(args,cap)
		end
		last_end = e + 1
		s,e,cap = self:find(pattern,last_end)
	end
	if last_end <= #self then
		cap = self:sub(last_end)
		table.insert(args,cap)
	end
	return args
end
