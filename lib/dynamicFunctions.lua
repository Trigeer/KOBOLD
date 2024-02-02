local dynamo = {}

-- A tool for seperate events to exchange information
local cache = {}

local function recalculateNormals(verteces, sectors, affected)
    for _, sector in pairs(affected) do
        for _, vertex in pairs(sector.points) do
            
            local xOff = verteces[sectors[sector].vertex[vertex + 1] + 1].x - verteces[sectors[sector].vertex[vertex] + 1].x
            local yOff = verteces[sectors[sector].vertex[vertex + 1] + 1].y - verteces[sectors[sector].vertex[vertex] + 1].y

            local wallLen = math.sqrt(xOff^2 + yOff^2)
            local wallSin =  yOff / wallLen
            local wallCos = -xOff / wallLen

            sectors[sector].vertex[vertex] = {idx = sectors[sector].vertex[vertex], dx = wallSin, dy = wallCos}

        end
    end
end

local function vertexEvent(verteces, event, dt)
    event.clock = (event.clock + dt) % event.loopTime
    local results = event:code(cache)
    for idx, ref in pairs(event.group) do
        verteces[ref + 1] = results[idx]
    end
end

local function slopeEvent(sectors, event, dt)
    event.clock = (event.clock + dt) % event.loopTime
    local results = event:code(cache)
    for idx, ref in pairs(event.group) do
        sectors[ref + 1].floor = results[idx].floor
        sectors[ref + 1].ceil  = results[idx].ceil
    end
end

local function playerEvent(camera, event, dt)
    event.clock = (event.clock + dt) % event.loopTime
    camera = event:code(cache)
end

dynamo.executeEvents = function (verteces, sectors, camera, events, dt)
    for _, event in pairs(events) do
        if event.type == 0 then -- vertex group
            vertexEvent(verteces, event, dt)
            recalculateNormals(verteces, sectors, event.affected)
        elseif event.type == 1 then -- slope group
            slopeEvent(sectors, event, dt)
        elseif event.type == 2 then -- player event
            playerEvent(camera, event, dt)
        end
    end
end

return dynamo