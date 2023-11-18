-- Imports
require("constants")
local geo = require("lib.geometricFunctions")

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
    
    -- Prepare the sector data
    local sectorArr = mapData.sector
    for idx = 1, #sectorArr do
        -- Loop the sector
        table.insert(sectorArr[idx].vertex, 1, sectorArr[idx].vertex[#sectorArr[idx].vertex])
    end

    -- Calculate colliders I
    local offsetArr = {}
    for _, sector in pairs(sectorArr) do
        local tmp = {}
        for idx = 1, #sector.vertex - 1 do
            
            local xOff = vertexArr[sector.vertex[idx + 1] + 1].x - vertexArr[sector.vertex[idx] + 1].x
            local yOff = vertexArr[sector.vertex[idx + 1] + 1].y - vertexArr[sector.vertex[idx] + 1].y

            local wallLen = math.sqrt(xOff^2 + yOff^2)
            local wallSin = yOff / wallLen
            local wallCos = xOff / wallLen

            table.insert(tmp, {
                p = {
                    x = vertexArr[sector.vertex[idx] + 1].x - Radius * wallSin,
                    y = vertexArr[sector.vertex[idx] + 1].y + Radius * wallCos
                },
                n = {
                    x = vertexArr[sector.vertex[idx + 1] + 1].x - Radius * wallSin,
                    y = vertexArr[sector.vertex[idx + 1] + 1].y + Radius * wallCos
                }
            })

        end
        table.insert(tmp, 1, tmp[#tmp])
        table.insert(offsetArr, tmp)
    end

    -- Calculate collider II
    for sect, sector in pairs(offsetArr) do
        local tmp = {}
        for idx = 1, #sector - 1 do
            local px1 = sector[idx + 0].p.x
            local py1 = sector[idx + 0].p.y
            local px2 = sector[idx + 0].n.x
            local py2 = sector[idx + 0].n.y
            local cx1 = sector[idx + 1].p.x
            local cy1 = sector[idx + 1].p.y
            local cx2 = sector[idx + 1].n.x
            local cy2 = sector[idx + 1].n.y

            local inter = {}
            if px2 == cx1 and py2 == cy1 then
                inter = {x = px2, y = py2}
            else
                inter = geo.intersect(geo.intercheck(px1, py1, px2, py2, cx1, cy1, cx2, cy2).uAB, px1, py1, px2, py2)
            end

            table.insert(tmp, inter)
        end
        table.insert(tmp, tmp[1])
        sectorArr[sect].collisions = tmp
    end

    -- Calculate collider III
    for sect, sector in pairs(sectorArr) do
        for idx = 1, #sector.collisions - 1 do
            local xOff = sector.collisions[idx + 1].x - sector.collisions[idx].x
            local yOff = sector.collisions[idx + 1].y - sector.collisions[idx].y
            local wallLen = math.sqrt(xOff^2 + yOff^2)

            if wallLen == 0 then wallLen = 0.00001 end
            
            sectorArr[sect].collisions[idx].dx =  yOff / wallLen
            sectorArr[sect].collisions[idx].dy = -xOff / wallLen
        end
    end
    
    -- Initialize the player data
    local p = mapData.player
    local camera = {
        where = {
            x = p.x,
            y = p.y,
            z = geo.planeZ(sectorArr[p.sector + 1].floor, 0, 0, p.x, p.y) + EyeHeight
        },
        angle = p.angle,
        sector = p.sector,
        pitch = 0,

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

return loader