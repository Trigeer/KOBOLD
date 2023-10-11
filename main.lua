io.stdout:setvbuf("no")

require("constants")
local gpx = require("lib.graphicFunctions")
-- local geo = require("geometricFunctions")

local vertexArr = nil
local sectorArr = nil
local camera = nil

-- Will be moved to separate file soon
function love.load()
    local mapData = love.filesystem.load("maps/map0.lua")()

    -- Flatten the vertex table
    vertexArr = {}
    for _, vertex in pairs(mapData.vertex) do
        local y = vertex.y
        for _, x in pairs(vertex.x) do
            table.insert(vertexArr, {x = x, y = y})
        end
    end

    -- Prepare the sector data
    sectorArr = mapData.sector
    for idx = 1, #sectorArr do
        -- Loop the sector
        table.insert(sectorArr[idx].vertex, 1, sectorArr[idx].vertex[#sectorArr[idx].vertex])

        -- Quick access loop size
        sectorArr[idx].npoints = #sectorArr[idx].vertex - 1
    end

    -- Initialize the player data
    local p = mapData.player
    camera = {
        where = {
            x = p.x,
            y = p.y,
            z = sectorArr[p.sector + 1].floor + EyeHeight
        },
        angle = p.angle,
        sector = p.sector,
        pitch = 0
    }
end

function love.update(dt)

end

function love.draw()
    gpx.drawScreen(vertexArr, sectorArr, camera)
end