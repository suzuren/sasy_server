
local _socket_pool = {}
local socketmanager = {}
local _socketsize = 0
function socketmanager.setclient(fd)
	if fd then
		table.insert(_socket_pool, fd)
		_socketsize = _socketsize + 1
		print("manager_socket.lua setclient - _socketsize, fd -",_socketsize, fd)
	end
end

function socketmanager.popclient(fd)
	if fd then
		for i=1, _socketsize do
			if fd == _socket_pool[i] then
				local success = table.remove(_socket_pool, i)
				if success then
					_socketsize = _socketsize - 1
					print("manager_socket.lua popclient - _socketsize, fd -",_socketsize, fd)
					break
				end
			end
		end
	end
end

function socketmanager.putclient(socket, id, uin, cmd, len, msg)
	for i=1, _socketsize do
		socket.write_chat(_socket_pool[i],uin, cmd, len, msg)
	end
end

return socketmanager


