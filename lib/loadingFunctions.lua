-- Imports
require("constants")
local geo = require("lib.helpers.geometricFunctions")

local loader = {}

loader.loadMapGeometry = function (path)
    local mapData = love.filesystem.load(path)()

    -- Flatten the vertex table
    local vertexArr = {}
    for _, vertex in pairs(mapData.vertex) do
        local y = vertex.y
        for _, x in pairs(vertex.x) do
            table.insert(vertexArr, {x = x, y = y})
        end
    end

    -- Prepare the sector data and colliders
    local sectorArr = mapData.sector
    for sidx, sector in pairs(sectorArr) do
        -- Loop the sector
        table.insert(sectorArr[sidx].vertex, 1, sector.vertex[#sector.vertex])

        -- Prepare normalized collider direction
        for idx = 1, #sector.vertex - 1 do
            local xOff = vertexArr[sector.vertex[idx + 1] + 1].x - vertexArr[sector.vertex[idx] + 1].x
            local yOff = vertexArr[sector.vertex[idx + 1] + 1].y - vertexArr[sector.vertex[idx] + 1].y

            local wallLen = math.sqrt(xOff^2 + yOff^2)
            local wallSin =  yOff / wallLen
            local wallCos = -xOff / wallLen

            local copy = sector.vertex[idx]
            sectorArr[sidx].vertex[idx] = {idx = copy, dx = wallSin, dy = wallCos}
        end
        sectorArr[sidx].vertex[#sector.vertex] = {idx = sector.vertex[#sector.vertex]}
    end
    
    -- Initialize the player data
    local p = mapData.player
    local camera = {
        where = {
            x = p.x,
            y = p.y,
            z = geo.planeZ(sectorArr[p.sector + 1].floor, 0, 0, p.x, p.y) + EyeHeight + 1e-5
        },
        angle  = p.angle,
        sector = p.sector,
        pitch  = 0,

        -- Control values
        velocity = {x = 0, y = 0, z = 0},
        grounded = false
    }

    return {vertexArr, sectorArr, camera}

end

loader.loadMapTexturing = function (path)
    local textureData = love.filesystem.load(path)()
    local texture = love.image.newImageData(textureData.texFile)
    return {sheet = texture, texDim = textureData.texDim, sector = textureData.sector}
end

loader.loadMapDynamics = function (path)
    
end

return loader