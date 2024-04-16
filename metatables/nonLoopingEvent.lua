-- Imports
local Event = require("metatables.event")

local NonLoopingEvent = Event:new()

function NonLoopingEvent:advanceClock (dt)
    self.clock = self.clock + dt
    
    if self.clock >= self.loop then
        self.clock = self.loop
        self.enabled = false
    end
end

return NonLoopingEvent