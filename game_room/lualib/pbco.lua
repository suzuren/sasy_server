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
	prototype 模拟一个对象
	new 方法类似于实例化一个对象, o 可存放一些初始值作用等同于 o 是 prototype 的子类。
	解释: prototype 这个 table 有一个属性 protoNoHash，通过 new 函数实例化一个类继承于 prototype。
	在 lua 中类、父类都是通过 table 数据结构加上元表元方法来实现。

	__index 是 lua 一个元方法，被广泛的使用在模拟实现继承方法。访问一个 table 中不存在的key，lua 将会返回一个 nil。
	但一个表存在元表的值可能会发生改变。既访问不存在的 key 时，如果这个 table 存在元表，就会尝试在它的元表中寻找
	是否存在匹配key对应的 value。

	: 是 lua 面向对象的语法糖。prototype:new(dir) 等同于 prototype.new(self, dir),相当于将调用者自身当做第一个参数，
	使用冒号调用就相当于隐式地传递 self 参数。
]]

function prototype:new(dir)
	local o = { pbFileDir=dir, protoNoHash={ encode={}, decode={} } }
	setmetatable(o, self)	-- 把 prototype 表设置为 o 的元表
	self.__index = self		-- 把 prototype 设置为 prototype 元方法,也就是prototype作为一个基类
							-- 访问对象 o 不存在的元素的时候，会访问元表 __index 指向的对象
	return o
end

return prototype
