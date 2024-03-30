-- Dynamic scripted events
--
local Event = {
    flags = {},
    clock = 0,
    loop  = 0,
    code = function (sectors, clock, flags, cache)
        print("Empty...")
    end
}

-- Create new sector
function Event:new (flags, loop, code)
    local event = {
        flags = flags or {},
        loop  = loop  or 0,
        code  = code  or nil
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