---------------------------------------------------------------------
--- 服务节点启动逻辑
---------------------------------------------------------------------
local skynet = require "skynet"
local dns = require "skynet.dns"
local crypt = require "skynet.crypt"
local socket = require "http.sockethelper"
local string = string

local function class(cname, super)
    local clazz = {}
    clazz.__cname = cname
    clazz.__index = clazz
    if type(super) == "table" then
        setmetatable(clazz, {__index = super})
    else
        clazz.ctor = function() end
    end
    
    function clazz.new(...)
        local instance = setmetatable({}, clazz)
        instance:ctor(...)
        return instance
    end
    return clazz
end

local SSLCTX_CLIENT = nil
local function gen_interface(fd)
    local tls = require "http.tlshelper"
    SSLCTX_CLIENT = SSLCTX_CLIENT or tls.newctx()
    local tls_ctx = tls.newtls("client", SSLCTX_CLIENT)
    return {
        init = tls.init_requestfunc(fd, tls_ctx),
        close = tls.closefunc(tls_ctx),
        read = tls.readfunc(fd, tls_ctx),
        write = tls.writefunc(fd, tls_ctx),
        readall = tls.readallfunc(fd, tls_ctx),
    }
end

function string.split(input, sep)
    local retval = {}
    string.gsub(input, string.format("([^%s]+)", (sep or "\t")), function(c)
        table.insert(retval, c)
    end)
    return retval
end

local function read_mail(read)
    local msgs = {}
    while true do
        local msg = read()
        skynet.error("mail:", msg)
        if not msg or #msg == 0 or msg == "\r\n" then
            break
        end
        local msgs = string.split(msg, "\r\n")
        local msg = msgs[#msgs]
        assert(msg)
        local code, opt, info = msg:match "(%d+)([%s-])(.*)"
        code = tonumber(code)
        if opt == " " and code ~= 220 then
            return code, opt, info
        end
    end
end

local cmd = {}

function cmd.hello(mailer)
    local code, opt, info = mailer:send_msg("EHLO HYL-PC\r\n")
    if code == 220 then
        code, opt, info = mailer:read_msg()
    end
    assert(code == 250)
    cmd.auth(mailer)
end

function cmd.auth(mailer)
    local code, opt, info = mailer:send_msg("AUTH LOGIN\r\n")
    assert(code == 334)
    cmd.username(mailer)
end

function cmd.username(mailer)
    local user = crypt.base64encode(mailer:get_smtp_user())
    local code, opt, info = mailer:send_msg(user.."\r\n")
    assert(code == 334)
    cmd.password(mailer)
end

function cmd.password(mailer)
    local token = crypt.base64encode(mailer:get_smtp_token())
    local code, opt, info = mailer:send_msg(token.."\r\n")
    assert(code == 235)
    cmd.mailfrom(mailer)
end

function cmd.mailfrom(mailer)
    local msg = string.format("MAIL FROM: <%s>\r\n", mailer:get_mailfrom())
    local code, opt, info = mailer:send_msg(msg)
    assert(code == 250)
    cmd.rcptto(mailer)
end

function cmd.rcptto(mailer)
    local msg = string.format("RCPT TO:<%s>\r\n", mailer:get_rcptto())
    local code, opt, info = mailer:send_msg(msg)
    assert(code == 250)
    cmd.data(mailer)
end

function cmd.data(mailer)
    local code, opt, info = mailer:send_msg("DATA\r\n")
    assert(code == 354)
    cmd.email(mailer)
end

function cmd.email(mailer)
    local msg = string.format("From:<%s>\r\nTo:<%s>\r\nCc:<%s>\r\nSubject:%s\r\n\r\n%s\r\n.\r\n",
        mailer:get_mailfrom(),
        mailer:get_rcptto(),
        mailer:get_mailfrom(),
        mailer:get_subject(),
        mailer:get_content())
    local code, opt, info = mailer:send_msg(msg)
    assert(code == 250)
    cmd.quit(mailer)
end

function cmd.quit(mailer)
    mailer:write("QUIT\r\n")
end

-------------------------
--------------------------

local Mailer = class("Mailer")

function Mailer:ctor(opt)
    local mail_ip = dns.resolve(opt.host)
    local fd = socket.connect(mail_ip, opt.port, 30*100)
    if not fd then
        error(string.format("connect error mail_ip:%s, mail_port:%s", opt.host, opt.port))
        return
    end
    local interface = gen_interface(fd)
    if interface.init then
        interface.init()
    end
    self.opt = opt
    self.interface = interface
    self.fd = fd
end

function Mailer:write(...)
    skynet.error("write:", ...)
    return self.interface.write(...)
end

function Mailer:read(...)
    local data = self.interface.read(...)
    skynet.error("read:", data)
    return data
end

function Mailer:send_msg(msg)
    self:write(msg)
    return self:read_msg()
end

function Mailer:read_msg()
    local msg, msgs
    while true do
        msg = self:read()
        if not msg or #msg == 0 or msg == "\r\n" then
            break
        end
        msgs = string.split(msg, "\r\n")
        msg = msgs[#msgs]
        assert(msg)
        local code, opt, info = msg:match "(%d+)([%s-])(.*)"
        code = tonumber(code)
        if opt == " " then
            return code, opt, info
        end
    end
end

function Mailer:get_smtp_user()
    return self.opt.user
end

function Mailer:get_smtp_token()
    return self.opt.token
end

function Mailer:get_mailfrom()
    return self.email.from or self.opt.user
end

function Mailer:get_rcptto()
    return self.email.to or self.opt.user
end

function Mailer:get_subject()
    return self.email.subject or "[skynetlua]未设置邮件标题"
end

function Mailer:get_content()
    return self.email.content or "[skynetlua]未设置邮件内容"
end

function Mailer:send(email)
    self.email = email
    cmd.hello(self)
end

function Mailer:close()
    socket.close(self.fd)
    local interface = self.interface
    if interface.close then
        interface.close()
    end
end

--------------------------
-------------------------
local command = {}

-- mail_opts = {
--     host = 'smtp.qq.com',
--     port = 465,
--     user = "@foxmail.com",
--     token = "cah",
-- },
-- local email = {
--     from    = from,
--     to      = to,
--     subject = subject,
--     html    = html
-- }
function command.send_email(email, opt)
    local mailer = Mailer.new(opt)
    mailer:send(email)
    mailer:close()
end

skynet.start(function()
    skynet.dispatch("lua", function(_,_,cmd,...)
        local f = command[cmd]
        if f then
            skynet.ret(skynet.pack(f(...)))
        else
            assert(false, "error no support cmd"..cmd)
        end
    end)
end)

