local net = {}

local luna = require("lib.dependencies.lunajson")
local socket = require("socket")

local server
local uuid

net.connect = function (host_ip, port, name)
    server = assert(socket.tcp())

    local ip = socket.dns.toip(host_ip)
    print(ip)

    server:connect(ip, port)
    uuid = server:receive() + 1
    local geom = server:receive()
    server:send(name .. "\r\n")
    return geom
end

net.send = function (dt, mod, jump, rotation)
    local jmp
    if jump then jmp = "true" else jmp = "false" end
    local msg = '{"dt": ' .. dt .. ', "direction": ' .. mod.ws .. ', "strafe": ' .. mod.ad .. ', "jump": ' .. jmp .. ', "rotation": ' .. rotation .. '}\r\n'
    server:send(msg)
end

net.receive = function ()
    local serial = nil
    local response = server:receive()
    local rec = server:receive()
    local decoded = nil
    if response then
        decoded = luna.decode(rec)
        if response == "2" then
            serial = server:receive()
        end
    end
    
    return decoded, uuid, serial
end

net.close = function ()
    server:send('iquit\r\n')
    server:close()
end

return net