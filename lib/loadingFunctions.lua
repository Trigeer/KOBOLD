-- Imports
                      require("constants")
local geo           = require("lib.geometricFunctions")
local Sector        = require("metatables.sector")
local SlantedSector = require("metatables.slantedSector")

local loader = {}

loader.loadMapGeometry = function (path)
    local mapData = love.filesystem.load(path)()

    -- Flatten the vertex table
    local vertexArr = {}
    for _, vertex in ipairs(mapData.nodes) do
        local y = vertex.y
        for _, x in ipairs(vertex.x) do
            table.insert(vertexArr, {x = x, y = y})
        end
    end

    -- Prepare the sector data
    local sectorArr = {}
    for _, sector in ipairs(mapData.sector) do
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

return loader