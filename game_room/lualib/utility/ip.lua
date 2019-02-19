local function getAddressOfIP(ip)
	local i = string.find(ip, ":", 1, true)
	if i ~= nil then
		ip = string.sub(ip, 1, i-1)
	end
	return ip
end

return {
	getAddressOfIP = getAddressOfIP,
}
