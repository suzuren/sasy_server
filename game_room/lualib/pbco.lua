local protobuf = require "protobuf"
local _loadedFileHash = {}
local pbcc = require "pbcc"


local prototype = {
	pbFileDir = "",
	protoNoHash = {
		encode={},
		decode={},
	}
}

function prototype:decode(protoNo,msg,sz,isDirectionReversed)
	local typeName 
	if isDirectionReversed then
		typeName = self.protoNoHash.encode[protoNo]
	else
		typeName = self.protoNoHash.decode[protoNo]
	end
	
	if not typeName then
		error(string.format("protocal 0x%06X not found", protoNo))
	end
	--print(typeName, msg, sz)
	local obj, err = protobuf.decode(typeName, msg, sz)
	if not obj then
		error(string.format("decode protocal 0x%06X error: %s", protoNo, err))
	end
	return obj
end


function prototype:encode(protoNo,obj)
	local typeName = self.protoNoHash.encode[protoNo]
	if not typeName then
		error(string.format("protocal 0x%06X not found", protoNo))
	end
	return protobuf.encode(typeName, obj)
end

function prototype:encode2netPacket(protoNo, obj, returnString)
	local typeName = self.protoNoHash.encode[protoNo]
	if not typeName then
		error(string.format("protocal 0x%06X not found", protoNo))
	end

	--[[
	local msg, size = protobuf.encode(typeName, obj, pbcc.packNetPacket, protoNo, returnString)
	print(msg, size)
	return msg, size;
--]]
	return protobuf.encode(typeName, obj, pbcc.packNetPacket, protoNo, returnString)
end

function prototype:config(protoDecodeHash, protoEncodeHash, pbFileArray)
	for protoNo, typeName in pairs(protoDecodeHash) do
		self.protoNoHash.decode[protoNo] = typeName
	end	
	
	for protoNo, typeName in pairs(protoEncodeHash) do
		self.protoNoHash.encode[protoNo] = typeName
	end

	for _, v in pairs(pbFileArray) do
		if not _loadedFileHash[v] then
			local file = string.format("%s/%s", self.pbFileDir, v)
			--print("register pb file: "..file)
			protobuf.register_file(file);
			_loadedFileHash[v] = true
		end
	end
end

function prototype:new(dir)
	local o = { pbFileDir=dir, protoNoHash={ encode={}, decode={} } }
	setmetatable(o, self)
	self.__index = self
	return o
end

return prototype
