-- Imports
require("constants")

local luna = require("lib.dependencies.lunajson")

local Sector        = require("metatables.sector")
local SlantedSector = require("metatables.slantedSector")
local Event         = require("metatables.event")
local Trigger       = require("metatables.trigger")
local Controller    = require("metatables.controller")

local loader = {}

loader.loadMapGeometry = function (path)
    -- local mapData = love.filesystem.load(path)()
    local file = love.filesystem.read(path)
    local mapData = luna.decode(file)

    if mapData == nil then
        error("Map not loaded...")
    end

    -- Flatten the vertex table
    local vertexArr = {}
    for _, vertex in ipairs(mapData.nodes) do
        local y = vertex.y
        for _, x in ipairs(vertex.x) do
            table.insert(vertexArr, {x = x, y = y})
        end
    end

    -- local vertexArr = {}
    -- for _, vertex in ipairs(mapData.nodes) do
    --     table.insert(vertexArr, {x = vertex.x, y = vertex.y})
    -- end

    -- Prepare the sector data
    local sectorArr = {}
    for _, sector in ipairs(mapData.sectors) do
        -- Translate nodes to points
        local nodes = {}
        for _, node in ipairs(sector.nodes) do
            table.insert(nodes, vertexArr[node + 1])
        end

        -- Reindex links
        local links = sector.links
        for i, wall in ipairs(links) do
            for j, link in ipairs(wall) do
                links[i][j] = link + 1
            end
        end

        if sector.slanted then
            local ceil  = sector.ceil
            local floor = sector.floor
            table.insert(sectorArr, SlantedSector:new(
                nodes,
                links,
                {height = ceil[1],  dx = ceil[2],  dy = ceil[3]},
                {height = floor[1], dx = floor[2], dy = floor[3]}
            ))
        else
            table.insert(sectorArr, Sector:new(
                nodes,
                links,
                sector.ceil,
                sector.floor
            ))
        end
    end
    
    -- Initialize the player data
    local p = mapData.player
    local camera = {
        where = {
            x = p.x,
            y = p.y,
            z = sectorArr[p.sector + 1]:floor(p) + EyeHeight + 1e-5
        },
        angle  = p.angle,
        sector = p.sector + 1,
        pitch  = 0,

        -- Control values
        velocity = {x = 0, y = 0, z = 0},
        grounded = false
    }

    return {sectorArr, camera}
end

loader.loadMapTexturing = function (path)
    local textureData = love.filesystem.load(path)()
    local texture = love.image.newImageData(textureData.texFile)
    return {sheet = texture, texDim = textureData.texDim, sector = textureData.sector}
end

loader.loadMapDynamics = function (path, sectors)
    local file = love.filesystem.read(path)
    local eventData = luna.decode(file)

    if eventData == nil then
        error("Events not loaded...")
    end

    local flags = {}

    local contrArr = {}
    local triggArr = {}
    local eventArr = {}

    for _, src in ipairs(eventData.sources) do
        local func, err = loadfile(src)

        if not func then
            print("Error: " .. err)
        else
            func()
        end
    end

    for _, event in pairs(eventData.functions) do
        if _G[event.name] then
            if event.type == "event" then
                table.insert(eventArr, Event:new(
                    event.enabled,
                    event.looping,
                    event.loop,
                    _G[event.name]
                ))
            elseif event.type == "trigger" then
                table.insert(triggArr, Trigger:new(
                    event.enabled,
                    _G[event.name]
                ))

                if event.kind == "onPortal" then
                    table.insert(sectors[event.attach[1]].triggers.onPortal[event.attach[2]], #triggArr)
                else
                    table.insert(sectors[event.attach[1]].triggers[event.kind], #triggArr)
                    -- table.insert(sectors[event.attach[1]].triggers, #triggArr)
                end
            elseif event.type == "controller" then
                table.insert(contrArr, Controller:new(
                    event.enabled,
                    _G[event.name]
                ))
            else
                print("Not supported...")
            end
        end
    end

    flags = eventData.flags

    return contrArr, triggArr, eventArr, flags
end

return loader