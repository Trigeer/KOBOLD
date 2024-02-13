local dynamo = {}

-- A tool for seperate events to exchange information
local cache = {}
local scheduler = {}

local function executeTrigger(trigger, visited, camera, action)
    if not trigger.actionable or action then
        if trigger.universal then
            table.insert(scheduler, trigger:code(camera, cache))
            do return true end
        else
            for _, sec in pairs(trigger.area) do
                for _, v in pairs(visited) do 
                    if sec == v then
                        table.insert(scheduler, trigger:code(camera, cache))
                        do return true end
                    end
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


-- trigger = {actionable = true, universal = false, area = {}, code = function (camera, cache)
    -- return event
-- end}