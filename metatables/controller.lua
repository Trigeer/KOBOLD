-- Dynamic scripted events
local Controller = {
    enabled = true,
    code = function (flags)
        print("Empty...")
    end
}

-- Create new sector
function Controller:new (enabled, code)
    local controller = {
        enabled = enabled or true,
        code    = code    or function (clock) print("Empty...") end
    }

    setmetatable(controller, self)
    self.__index = self

    return controller
end

function Controller:execute (flags)
    return self.code(flags)
end

return Controller