table.deepcopy = function(original)
	assert(type(original)=="table", "argument must be a table")
	
	local ret = {}
	for k, v in pairs(original) do
		ret[k] = v
	end
	return ret
end

table.countHash = function(t)
	local i = 0
	for k, v in pairs(t) do
		i = i + 1
	end
	return i
end

table.copy = function (ori_tab)
	if type(ori_tab) ~= "table" then
        return
    end
    local new_tab = {}
    for k,v in pairs(ori_tab) do
        local vtype = type(v)
        if vtype == "table" then
            new_tab[k] = table.copy(v)
        else
            new_tab[k] = v
        end
    end
    return new_tab
end

table.fill = function(tag_tab, src_tab)
    if type(src_tab) ~= "table" then
        return
    end
    if type(tag_tab) ~= "table" then
        return
    end
    for k,v in pairs(src_tab) do
        local vtype = type(v)
        if vtype == "table" then
			tag_tab[#tag_tab+1] = {}
            table.fill(tag_tab[#tag_tab], v)
        else
            tag_tab[#tag_tab+1] = v
        end
    end
end


table.clear = function(v_table)
    if type(v_table) ~= "table" then
        return
    end
	for k,v in pairs(v_table) do
		v_table[k] = nil
	end	
end

table.removeall = function(v_table)
    if type(v_table) ~= "table" then
        return
    end
	for i=#v_table, 1, -1  do
		table.remove(v_table, i)
	end
end

table.init = function(n,v)
	local t = {}
    if type(n) ~= "number" then
        return
    end
	if not v then v = 0	end
	if type(v) == "table" then
		if v == {} then
			for i=1,n do
		    	t[i] =  {}
		    end
		else
			for i=1,n do
				local v_t = table.copy(v)
		    	t[i] =  v_t
		    end
		end	

	else
		for i=1,n do
    		t[i] =  v
    	end
	end

	return t
end

table.pushback = function(t,v)
	if type(t) == "table" then
		if type(v) == "table" then
			if v == {} then
				t[#t + 1] =  {}
			else
				local v_t = table.copy(v)
			    t[#t + 1] =  v_t
			end	
		else
			t[#t + 1] = v
		end
	end
end

table.back = function(t)
	if type(t) == "table" then
		return t[#t]
	end
	return nil
end

table.front = function(t)
	if type(t) == "table" then
		return t[1]
	end
	return nil
end