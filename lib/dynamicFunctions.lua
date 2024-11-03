local dynamo = {}

local function executor (actions, sectors, events, controllers, triggers, flags)
    for _, action in ipairs(actions) do
        if action.type == "sector" then
            if (action.subtype == "topPlane" or action.subtype == "bottomPlane") and sectors[action.locate.index + 1]._type == "Sector" then
                sectors[action.locate.index + 1][action.subtype] = action.newValue
            elseif action.subtype == "nodes" then
                if action.locate.coord == "x" then
                    sectors[action.locate.index + 1]:nodeSet(action.locate.detail + 1, action.newValue, sectors[action.locate.index + 1]:nodeAt(action.locate.detail + 1).y)
                else
                    sectors[action.locate.index + 1]:nodeSet(action.locate.detail + 1, sectors[action.locate.index + 1]:nodeAt(action.locate.detail + 1).x, action.newValue)
                end
            else
                sectors[action.locate.index + 1][action.subtype][action.locate.detail + 1] = action.newValue
            end
        elseif action.type == "event" then
            events[action.locate.index + 1][action.subtype] = action.newValue
        elseif action.type == "controller" then
            controllers[action.locate.index + 1].enabled = action.newValue
        elseif action.type == "trigger" then
            triggers[action.locate.index + 1].enabled = action.newValue
        elseif action.type == "flag" then
            flags[action.locate.index] = action.newValue
        end
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
