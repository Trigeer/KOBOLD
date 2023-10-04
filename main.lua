-- io.stdout:setvbuf("no")

require("constants")
local geo = require("geometricFunctions")

-- Will be moved to separate file soon
function love.load()
    local mapData = love.filesystem.load("maps/map0.lua")()

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
    for idx, sector in pairs(sectorArr) do
        -- Replace vertex index with proper coordinates
        -- TODO: In future needs to be more dynamic, most likely reverted to vertex index
        for vidx, vertex in sector.vertex do
            sectorArr[idx].vertex[vidx] = vertexArr[vertex + 1]
        end
        -- Loop the sector
        table.insert(sectorArr[idx].vertex, 1, sectorArr[idx].vertex[#sectorArr[idx].vertex])

        -- Do we need it really?
        sectorArr[idx].npoints = #sectorArr[idx].vertex
    end

    -- Initialize the player data
    local p = mapData.player
    local player = {
        where = {
            x = p.x,
            y = p.y,
            z = sectorArr[p.sector + 1].floor + EyeHeight
        },
        angle = p.angle,
        sector = p.sector,
        velocity = { x = 0, y = 0, z = 0 },
        pitch = 0,
        ground = false,
        falling = true
    }

    return {sectorArr, player}
end

function love.update(dt)

end

function love.draw()
    for i = 1, 10 do
        love.graphics.print(tostring(i), 100, 30 + 20 * i)
    end
end