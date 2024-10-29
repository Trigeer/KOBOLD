local dynamo = {}

local function executor (actions, sectors, events, controllers, triggers, flags)
    for _, action in ipairs(actions) do
        -- if action.type == "sector" then
        --     sectors[action.locate.index + 1][action.subtype] = action.newValue
        -- end
    end
end

dynamo.executeEvents = function (sectors, events, controllers, triggers, flags, dt)
    for _, event in pairs(events) do
        if event.enabled then
            event:advanceClock(dt)
            local results = event:execute()

            executor(results, sectors, events, controllers, triggers, flags)
        end
    end
end

dynamo.control = function (sectors, events, controllers, triggers, flags)
    for _, controller in pairs(controllers) do
        if controller.enabled then
            local results = controller:execute(flags)

            executor(results, sectors, events, controllers, triggers, flags)
        end
    end
end

dynamo.checkTriggers = function (sectors, events, controllers, triggers, flags, refArr, sector_ref, entity)
    for _, trigger in pairs(refArr) do
        if triggers[trigger].enabled then
            local results = triggers[trigger]:execute(flags, sector_ref, entity)

            executor(results, sectors, events, controllers, triggers, flags)
        end
    end
end

return dynamo
