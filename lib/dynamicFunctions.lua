local dynamo = {}

-- A tool for seperate events to exchange information
local cache = {}

local function recalculateNormals(verteces, sectors, affected)
    
end

local function vertexEvent(verteces, event, dt)
    -- event.clock = (event.clock + dt) % event.loopTime
    local results = event:code(dt, cache)
    for idx, ref in pairs(event.group) do
        verteces[ref + 1] = results[idx]
    end
end

local function slopeEvent(sectors, event, dt)
    local results = event:code(dt, cache)
    for idx, ref in pairs(event.group) do
        sectors[ref + 1].floor = results[idx].floor
        sectors[ref + 1].ceil  = results[idx].ceil
    end
end

dynamo.executeEvents = function (verteces, sectors, events, dt)
    for _, event in pairs(events) do
        if event.type == 0 then -- vertex group
            vertexEvent(verteces, event, dt)
            recalculateNormals(verteces, sectors, event.affected)
        elseif event.type == 1 then -- slope group
            slopeEvent(sectors, event, dt)
        end
    end
end

return dynamo