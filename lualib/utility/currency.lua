local function formatCurrency(value)
	if value >= 10000000000 then
		return string.format("%.1f亿", value/100000000)
	elseif value >= 1000000000 then
		return string.format("%.2f亿", value/100000000)
	elseif value >= 100000000 then
		return string.format("%.3f亿", value/100000000)
	elseif value >= 1000000 then
		return string.format("%.0f万", value/10000)
	elseif value >= 100000 then
		return string.format("%.1f万", value/10000)
	elseif value >= 10000 then
		return string.format("%.2f万", value/10000)
	else
		return string.format("%d", value)
	end
end

return {
	formatCurrency = formatCurrency,
}