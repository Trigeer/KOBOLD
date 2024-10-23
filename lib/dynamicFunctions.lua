local dynamo = {}

-- A tool for seperate events to exchange information
-- local cache = {}

local function executor (actions)
    for _, action in ipairs(actions) do
        -- if action.type == "sector" then
        --     sectors[action.locate.index + 1][action.subtype] = action.newValue
        -- end
    end
end

dynamo.executeEvents = function (sectors, events, dt)
    for _, event in pairs(events) do
        if event.enabled then
            event:advanceClock(dt)
            local results = event:execute()

            executor(results)
        end
    end
end

dynamo.control = function (sectors, controllers, flags)
    for _, controller in pairs(controllers) do
        if controller.enabled then
            local results = controller:execute(flags)

            executor(results)
        end
    end
end

dynamo.checkTriggers = function (triggers, refArr, sector_ref, entity, flags)
    for _, trigger in pairs(refArr) do
        if triggers[trigger].enabled then
            local results = triggers[trigger]:execute(flags, sector_ref, entity)

            executor(results)
        end
    end
end

return dynamo
