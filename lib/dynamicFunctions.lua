local dynamo = {}

-- A tool for seperate events to exchange information
local cache = {}

dynamo.executeEvents = function (sectors, events, dt)
    for _, event in pairs(events) do
        if event.enabled then
            event:advanceClock(dt)
            event:execute(sectors, cache)
        end
    end
end

dynamo.checkTriggers = function (triggers, visited, camera, action)
    for _, trigger in pairs(triggers) do
        trigger:execute(visited, camera, action, cache)
    end
end

return dynamo
