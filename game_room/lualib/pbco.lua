local protobuf = require "protobuf"
local _loadedFileHash = {}
local pbcc = require "pbcc"

local skynet = require "skynet"
local inspect = require "inspect"

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
	--skynet.error(string.format("protoNo-0x%06X", protoNo))
	local typeName = self.protoNoHash.encode[protoNo]
	--print("typeName - ",typeName)
	if not typeName then
		error(string.format("protocal 0x%06X not found", protoNo))
	end

	--[[
	local msg, size = protobuf.encode(typeName, obj, pbcc.packNetPacket, protoNo, returnString)
	print(msg, size)
	return msg, size
	--]]
	--print("encode2netPacket - ",typeName, obj, pbcc.packNetPacket, protoNo, returnString)
	return protobuf.encode(typeName, obj, pbcc.packNetPacket, protoNo, returnString)
end

function prototype:config(protoDecodeHash, protoEncodeHash, pbFileArray)
	for protoNo, typeName in pairs(protoDecodeHash) do
		self.protoNoHash.decode[protoNo] = typeName
	end	
	
	for protoNo, typeName in pairs(protoEncodeHash) do
		--skynet.error(string.format("protoNo-0x%06X, typeName-%s", protoNo, typeName))
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

--[[
	prototype ģ��һ������
	new ����������ʵ����һ������, o �ɴ��һЩ��ʼֵ���õ�ͬ�� o �� prototype �����ࡣ
	����: prototype ��� table ��һ������ protoNoHash��ͨ�� new ����ʵ����һ����̳��� prototype��
	�� lua ���ࡢ���඼��ͨ�� table ���ݽṹ����Ԫ��Ԫ������ʵ�֡�

	__index �� lua һ��Ԫ���������㷺��ʹ����ģ��ʵ�ּ̳з���������һ�� table �в����ڵ�key��lua ���᷵��һ�� nil��
	��һ�������Ԫ���ֵ���ܻᷢ���ı䡣�ȷ��ʲ����ڵ� key ʱ�������� table ����Ԫ���ͻ᳢��������Ԫ����Ѱ��
	�Ƿ����ƥ��key��Ӧ�� value��

	: �� lua ���������﷨�ǡ�prototype:new(dir) ��ͬ�� prototype.new(self, dir),�൱�ڽ���������������һ��������
	ʹ��ð�ŵ��þ��൱����ʽ�ش��� self ������
]]

function prototype:new(dir)
	local o = { pbFileDir=dir, protoNoHash={ encode={}, decode={} } }
	setmetatable(o, self)	-- �� prototype ������Ϊ o ��Ԫ��
	self.__index = self		-- �� prototype ����Ϊ prototype Ԫ����,Ҳ����prototype��Ϊһ������
							-- ���ʶ��� o �����ڵ�Ԫ�ص�ʱ�򣬻����Ԫ�� __index ָ��Ķ���
	return o
end

return prototype
