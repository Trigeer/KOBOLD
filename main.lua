-- io.stdout:setvbuf("no")

require("constants")

function love.load()
    local mapData = love.filesystem.load("maps/map0.lua")()

    local vertexArr = {}
    for vertex in mapData.vertex do
        local y = vertex.y
        for x in vertex.x do
            table.insert(vertexArr, {x = x, y = y})
        end
    end

    local sectorArr = mapData.sector
    for idx = 1, #sectorArr do
        for vidx = 1, #sectorArr[idx].vertex do
            sectorArr[idx].vertex[vidx] = vertexArr[sectorArr[idx].vertex[vidx]]
        end
        table.insert(sectorArr[idx].vertex, 1, sectorArr[idx].vertex[#sectorArr[idx].vertex])
        sectorArr[idx].npoints = #sectorArr[idx].vertex
    end

    local p = mapData.player
    local player = {
        x = p.x,
        y = p.y,
        z = sectorArr[p.sector].floor + EyeHeight,
        angle = p.angle,
        sector = p.sector
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