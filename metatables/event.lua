-- Dynamic scripted events
--
local Event = {
    flags   = {},
    enabled = true,
    clock   = 0,
    loop    = 0,
    code = function (sectors, clock, flags, cache)
        print("Empty...")
    end
}

-- Create new sector
function Event:new (flags, enabled, loop, code)
    local event = {
        flags   = flags or {},
        enabled = enabled or true,
        loop    = loop  or 0,
        code    = code  or nil
    }

    setmetatable(event, self)
    self.__index = self

    return event
end

function Event:advanceClock (dt)
    self.clock = (self.clock + dt) % self.loop
end

function Event:execute (sectors, cache)
    self.code(sectors, self.clock, self.flags, cache)
end

return Event