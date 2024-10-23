-- Dynamic scripted events
local Event = {
    enabled = true,
    looping = true,
    clock   = 0,
    loop    = 0,
    code = function (clock)
        print("Empty...")
    end
}

-- Create new sector
function Event:new (enabled, looping, loop, code)
    local event = {
        enabled = enabled or true,
        looping = looping or true,
        loop    = loop    or 0,
        code    = code    or function (clock) print("Empty...") end
    }

    setmetatable(event, self)
    self.__index = self

    return event
end

function Event:advanceClock (dt)
    if self.looping then
        self.clock = (self.clock + dt) % self.loop
    else
        self.clock = self.clock + dt
    
        if self.clock >= self.loop then
            self.clock = self.loop
            self.enabled = false
        end
    end
end

function Event:execute ()
    return self.code(self.clock)
end

return Event