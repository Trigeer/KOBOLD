local dynamo = {}

-- A tool for seperate events to exchange information
local cache = {}

dynamo.executeEvents = function (sectors, events, dt)
    for _, event in pairs(events) do
        if event.enabled then
            event:advanceClock(dt)
            local results = event:execute()

            for _, action in ipairs(results) do
                if action.type == "sector" then
                    sectors[action.locate.index + 1][action.subtype] = action.newValue
                end
            end
        end
    end
end

dynamo.checkTriggers = function (triggers, visited, camera, action)
    for _, trigger in pairs(triggers) do
        trigger:execute(visited, camera, action, cache)
    end
end

return dynamo
