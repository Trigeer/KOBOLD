-- Imports
require("constants")
local geo  = require("lib.geometricFunctions")
local util = require("lib.utilities")

local graphics = {}

-- Local constants
local near = 0.00001

local function drawCenteredText(rectX, rectY, rectWidth, rectHeight, text)
	local font       = love.graphics.getFont()
	local textWidth  = font:getWidth(text)
	local textHeight = font:getHeight()
    love.graphics.setColor({0, 0, 0})
    love.graphics.rectangle("fill", rectX, rectY, rectWidth, rectHeight)
    love.graphics.setColor({1, 1, 1})
	love.graphics.print(text, rectX+rectWidth/2, rectY+rectHeight/2, 0, 1, 1, textWidth/2, textHeight/2)
end

-- A custom line method
local function vline(x, yTop, yLow, color)
    -- Limit the values to valid ranges
    x = math.abs(x)
    yTop = geo.clamp(yTop, -1, ScreenHeight)
    yLow = geo.clamp(yLow, -1, ScreenHeight)

    if yTop < yLow then
        love.graphics.setColor(color)
        love.graphics.rectangle(
            "fill",
            x * Scaling,
            yTop * Scaling,
            Scaling,
            (yLow - yTop) * Scaling
        )
    end
end

local function drawSector(verteces, sectors, camera, now, yTop, yLow, depth)
    local sector = sectors[now.sector]

    local camCos = math.cos(camera.angle)
    local camSin = math.sin(camera.angle)

    -- Save sector's origin
    local xOrigin = verteces[sector.vertex[1] + 1].x - camera.where.x
    local zOrigin = verteces[sector.vertex[1] + 1].y - camera.where.y

    -- Render each wall
    for s = 1, sector.npoints do
 
        -- Obtain the coordinates of 2 endpoints of rendered edge
        local vx0 = verteces[sector.vertex[s + 0] + 1].x - camera.where.x
        local vy0 = verteces[sector.vertex[s + 0] + 1].y - camera.where.y
        local vx1 = verteces[sector.vertex[s + 1] + 1].x - camera.where.x
        local vy1 = verteces[sector.vertex[s + 1] + 1].y - camera.where.y

        -- Rotate them around camera's view
        local tx0 = vx0 * camSin - vy0 * camCos
        local tz0 = vx0 * camCos + vy0 * camSin
        local tx1 = vx1 * camSin - vy1 * camCos
        local tz1 = vx1 * camCos + vy1 * camSin

        -- Only render if at least partially in front of the camera
        if tz0 <= near and tz1 <= near then goto continue end
        -- Clip against view frustrum
        if tz0 <= near or tz1 <= near then
            -- Calculate intersection point
            local inter = geo.intersect(geo.intercheck(
                    tx0, tz0, tx1, tz1,
                    -20, near,
                    20, near
                ).uAB, tx0, tz0, tx1, tz1
            )
            if tz0 < near then
                tx0 = inter.x
                tz0 = inter.y
            elseif tz1 < near then
                tx1 = inter.x
                tz1 = inter.y
            end
        end

        -- Perspective transformation
        local xScale0 = Hfov / tz0
        local yScale0 = Vfov / tz0
        local xScale1 = Hfov / tz1
        local yScale1 = Vfov / tz1
        local x0 = ScreenWidth / 2 - math.floor(tx0 * xScale0 + 0.5)
        local x1 = ScreenWidth / 2 - math.floor(tx1 * xScale1 + 0.5)
        -- Only render if visible
        if x0 >= x1 or x1 < now.sx0 or x0 > now.sx1 then goto continue end

        -- Obtain floor and ceiling heights, relative to camera position
        local yCeil0  = geo.planeZ(sector.ceil, xOrigin, zOrigin, vx0, vy0)  - camera.where.z
        local yFloor0 = geo.planeZ(sector.floor, xOrigin, zOrigin, vx0, vy0) - camera.where.z
        local yCeil1  = geo.planeZ(sector.ceil, xOrigin, zOrigin, vx1, vy1)  - camera.where.z
        local yFloor1 = geo.planeZ(sector.floor, xOrigin, zOrigin, vx1, vy1) - camera.where.z

        -- Project ceiling and floor heights onto screen y-coordinate
        yCeil0  = math.floor(ScreenHeight / 2) - math.floor((yCeil0  + tz0 * camera.pitch) * yScale0)
        yFloor0 = math.floor(ScreenHeight / 2) - math.floor((yFloor0 + tz0 * camera.pitch) * yScale0)
        yCeil1  = math.floor(ScreenHeight / 2) - math.floor((yCeil1  + tz1 * camera.pitch) * yScale1)
        yFloor1 = math.floor(ScreenHeight / 2) - math.floor((yFloor1 + tz1 * camera.pitch) * yScale1)

        -- Neighbor ceiling and floor
        local neighbor = sector.neighbor[s]
        local nCeil0  = {}
        local nFloor0 = {}
        local nCeil1  = {}
        local nFloor1 = {}
        if next(neighbor) ~= nil then

            for idx, n in pairs(neighbor) do
               
                -- Obtain floor and ceiling heights, relative to camera position
                local vnCeil0  = geo.planeZ(sectors[n + 1].ceil, xOrigin, zOrigin, vx0, vy0)  - camera.where.z
                local vnFloor0 = geo.planeZ(sectors[n + 1].floor, xOrigin, zOrigin, vx0, vy0) - camera.where.z
                local vnCeil1  = geo.planeZ(sectors[n + 1].ceil, xOrigin, zOrigin, vx1, vy1)  - camera.where.z
                local vnFloor1 = geo.planeZ(sectors[n + 1].floor, xOrigin, zOrigin, vx1, vy1) - camera.where.z

                -- Project ceiling and floor heights onto screen y-coordinate
                table.insert(nCeil0,  math.floor(ScreenHeight / 2) - math.floor((vnCeil0  + tz0 * camera.pitch) * yScale0))
                table.insert(nFloor0, math.floor(ScreenHeight / 2) - math.floor((vnFloor0 + tz0 * camera.pitch) * yScale0))
                table.insert(nCeil1,  math.floor(ScreenHeight / 2) - math.floor((vnCeil1  + tz1 * camera.pitch) * yScale1))
                table.insert(nFloor1, math.floor(ScreenHeight / 2) - math.floor((vnFloor1 + tz1 * camera.pitch) * yScale1))

                -- Ensure there is enough yTop, yLow tables
                if idx > 1 then
                    yTop[idx] = util.shallow(yTop[1])
                    yLow[idx] = util.shallow(yLow[1])
                end

            end

        end

        -- Render the wall
        local xBegin = math.max(x0, now.sx0)
        local xEnd   = math.min(x1, now.sx1)
        for x = xBegin, xEnd do
            
            -- Calculate this points z-coordinate for shading
            local zShade = math.abs(math.floor(((x - x0) * (tz1 - tz0) / (x1 - x0) + tz0) * 8))
            local xShade = math.abs(math.floor(((x - x0) * (tx1 - tx0) / (x1 - x0) + tx0) * 8))
            local shader = math.floor(math.sqrt(xShade^2 + zShade^2))

            -- Obtain y-coordinate for ceiling and floor for this x-coordinate, clamp them
            local ceil  = geo.clamp(math.floor((x - x0) * (yCeil1  - yCeil0)  / (x1 - x0) + yCeil0),  yTop[1][x + 1], yLow[1][x + 1])
            local floor = geo.clamp(math.floor((x - x0) * (yFloor1 - yFloor0) / (x1 - x0) + yFloor0), yTop[1][x + 1], yLow[1][x + 1])

            -- Render ceiling and floor: everything above and below relevent heights
            vline(x, yTop[1][x + 1] + 1, ceil,       {50/255, 50/255, 50/255}) -- Ceiling
            vline(x, floor + 1,      yLow[1][x + 1], {50/255, 50/255, 50/255}) -- Floor

            -- Set the color
            local hue = (255 - shader) / 255

            -- Render wall: depends if portal or not
            if next(neighbor) ~= nil then
                for idx = 1, #neighbor do
                    local nceil  = geo.clamp(math.floor((x - x0) * (nCeil1[idx]  - nCeil0[idx])  / (x1 - x0) + nCeil0[idx]),  yTop[idx][x + 1], yLow[idx][x + 1])
                    local nfloor = geo.clamp(math.floor((x - x0) * (nFloor1[idx] - nFloor0[idx]) / (x1 - x0) + nFloor0[idx]), yTop[idx][x + 1], yLow[idx][x + 1])

                    -- Render upper walls
                    if x ~= x0 and x ~= x1 then
                        vline(x, ceil + 1, nceil, {hue, hue, hue})
                    end
                    
                    -- Shrink the windows
                    yTop[idx][x + 1] = geo.clamp(math.max(ceil,  nceil),  yTop[idx][x + 1], ScreenHeight - 1)
                    yLow[idx][x + 1] = geo.clamp(math.min(floor, nfloor), 0,                yLow[idx][x + 1])

                    ceil = nfloor
                end

                -- Render lowest wall
                if x ~= x0 and x ~= x1 then
                    vline(x, ceil + 1, floor, {hue, hue, hue})
                end
                
            elseif x ~= x0 and x ~= x1 then
                vline(x, ceil + 1, floor, {hue, hue, hue})
            end

        end

        -- Schedule neighboring sector
        if next(neighbor) ~= nil and xEnd > xBegin and depth >= 0 then
            for idx = 1, #neighbor do
                drawSector(
                verteces, sectors, camera,
                {
                    sector = neighbor[idx] + 1,
                    sx0 = xBegin,
                    sx1 = xEnd
                },
                {yTop[idx]}, {yLow[idx]},
                depth - 1
            )
            end
        end

        ::continue::
    end
    
end

graphics.drawScreen = function (verteces, sectors, camera)
    -- Prepare screen bounds
    local yTop = {{}}
    local yLow = {{}}
    for i = 1, ScreenWidth do
        yTop[1][i] = -1
        yLow[1][i] = ScreenHeight
    end

    -- Begin from camera
    drawSector(
        verteces, sectors, camera,
        {
            sector = camera.sector + 1,
            sx0 = 0,
            sx1 = ScreenWidth - 1
        },
        yTop, yLow,
        RenderDepth
    )

    drawCenteredText(680, 10, 30, 25, camera.sector)
end

return graphics