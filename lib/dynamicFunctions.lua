local dynamo = {}

-- A tool for seperate events to exchange information
local cache = {}

dynamo.executeEvents = function (sectors, events, dt)
    for _, event in pairs(events) do
        event:advanceClock(dt)
        event:execute(sectors, cache)
    end
end

dynamo.checkTriggers = function (triggers, visited, camera, action)
    for _, trigger in pairs(triggers) do
        trigger:executeTrigger(visited, camera, action, cache)
    end
end

return dynamo
