local dynamo = {}

-- A tool for seperate events to exchange information
local cache = {}

local function executeTrigger(trigger, visited, camera, action)
    if not trigger.actionable or action then
        for _, sec in pairs(trigger.area) do
            for _, v in pairs(visited) do 
                if sec == v then
                    trigger:code(camera, cache)
                    do return true end
                end
            end
        end
    end
    do return false end
end

dynamo.checkTriggers = function (triggers, visited, camera, action)
    for _, trigger in pairs(triggers) do
        executeTrigger(trigger, visited, camera, action)
    end
end

return dynamo


-- trigger = {actionable = true, area = {}, code = function (camera, cache)
    
-- end}