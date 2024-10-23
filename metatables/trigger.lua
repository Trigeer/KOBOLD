-- Dynamic scripted events triggered on certain occasions
local Trigger = {
    enabled = true,
    code = function (flags, sector_ref, entity)
        print("Empty...")
    end
}

-- Create new trigger
function Trigger:new (enabled, code)
    local trigger = {
        enabled = enabled or true,
        code    = code    or function (flags, sector_ref, entity) print("Empty...") end
    }

    setmetatable(trigger, self)
    self.__index = self

    return trigger
end

function Trigger:execute (flags, sector_ref, entity)
    return self.code(flags, sector_ref, entity)
end

return Trigger