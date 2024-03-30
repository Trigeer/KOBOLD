-- Activable triggers
--
local Trigger = {
    flags = {},
    code = function (visited, camera, flags, cache)
        print("Empty...")
    end
}

-- Create new sector
function Trigger:new (flags, code)
    local trigger = {
        flags = flags or {},
        code  = code  or nil
    }

    setmetatable(trigger, self)
    self.__index = self

    return trigger
end

function Trigger:execute (visited, camera, action, cache)
    self.code(visited, camera, self.flags, cache)
end

return Trigger