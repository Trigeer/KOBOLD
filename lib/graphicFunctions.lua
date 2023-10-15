-- Imports
require("constants")
local geo = require("lib.geometricFunctions")

local graphics = {}

-- Local constants
local near = 0.00001

-- A custom line method
local function vline(x, yTop, yLow, color, outline)
    -- Limit the values to valid ranges
    x = math.abs(x)
    yTop = geo.clamp(yTop, 0, ScreenHeight)
    yLow = geo.clamp(yLow, 0, ScreenHeight)

    if yTop == yLow then
        love.graphics.setColor(color)
        love.graphics.rectangle(
            "fill",
            x * Scaling,
            yTop * Scaling,
            Scaling, Scaling -- Square
        )
    elseif yTop < yLow then
        -- Drawing the outline
        love.graphics.setColor(outline)
        love.graphics.rectangle(
            "fill",
            x * Scaling,
            yTop * Scaling,
            Scaling, Scaling -- Square
        )
        love.graphics.rectangle(
            "fill",
            x * Scaling,
            yLow * Scaling,
            Scaling, Scaling -- Square
        )
        -- Drawing the mainline
        love.graphics.setColor(color)
        love.graphics.rectangle(
            "fill",
            x * Scaling,
            (yTop + 1) * Scaling,
            Scaling,
            (yLow - yTop) * Scaling
        )
    end
end

local function drawSector(verteces, sectors, camera, now, yTop, yLow, depth)
    local sector = sectors[now.sector]

    -- Render each wall
    for s = 1, sector.npoints do
 
        -- Obtain the coordinates of 2 endpoints of rendered edge
        local vx0 = verteces[sector.vertex[s + 0] + 1].x - camera.where.x
        local vy0 = verteces[sector.vertex[s + 0] + 1].y - camera.where.y
        local vx1 = verteces[sector.vertex[s + 1] + 1].x - camera.where.x
        local vy1 = verteces[sector.vertex[s + 1] + 1].y - camera.where.y

        -- Rotate them around camera's view
        local camCos = math.cos(camera.angle)
        local camSin = math.sin(camera.angle)
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
        local yCeil  = sector.ceil  - camera.where.z
        local yFloor = sector.floor - camera.where.z

        -- Project ceiling and floor heights onto screen y-coordinate
        local yCeil0  = math.floor(ScreenHeight / 2) - math.floor((yCeil  + tz0 * camera.pitch) * yScale0)
        local yFloor0 = math.floor(ScreenHeight / 2) - math.floor((yFloor + tz0 * camera.pitch) * yScale0)
        local yCeil1  = math.floor(ScreenHeight / 2) - math.floor((yCeil  + tz1 * camera.pitch) * yScale1)
        local yFloor1 = math.floor(ScreenHeight / 2) - math.floor((yFloor + tz1 * camera.pitch) * yScale1)

        -- Neighbor ceiling and floor
        local neighbor = sector.neighbor[s]
        local nCeil0  = 0
        local nFloor0 = 0
        local nCeil1  = 0
        local nFloor1 = 0
        if next(neighbor) ~= nil then
            
            -- Obtain floor and ceiling heights, relative to camera position
            local nCeil  = sectors[neighbor[1] + 1].ceil  - camera.where.z
            local nFloor = sectors[neighbor[1] + 1].floor - camera.where.z

            -- Project ceiling and floor heights onto screen y-coordinate
            nCeil0  = math.floor(ScreenHeight / 2) - math.floor((nCeil  + tz0 * camera.pitch) * yScale0)
            nFloor0 = math.floor(ScreenHeight / 2) - math.floor((nFloor + tz0 * camera.pitch) * yScale0)
            nCeil1  = math.floor(ScreenHeight / 2) - math.floor((nCeil  + tz1 * camera.pitch) * yScale1)
            nFloor1 = math.floor(ScreenHeight / 2) - math.floor((nFloor + tz1 * camera.pitch) * yScale1)

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
            local ceil  = geo.clamp(math.floor((x - x0) * (yCeil1  - yCeil0)  / (x1 - x0) + yCeil0),  yTop[x + 1], yLow[x + 1])
            local floor = geo.clamp(math.floor((x - x0) * (yFloor1 - yFloor0) / (x1 - x0) + yFloor0), yTop[x + 1], yLow[x + 1])

            -- Render ceiling and floor: everything above and below relevent heights
            vline(x, yTop[x + 1],   ceil - 1, {50/255, 50/255, 50/255}, {0, 0, 0}) -- Ceiling
            vline(x, floor + 1, yLow[x + 1],  {50/255, 50/255, 50/255}, {0, 0, 0}) -- Floor

            -- Set the color
            local hue = nil
            if x == x0 or x == x1 then hue = 0 else hue = (255 - shader) / 255 end

            -- Render wall: depends if portal or not
            if next(neighbor) ~= nil then
                local nceil  = geo.clamp(math.floor((x - x0) * (nCeil1  - nCeil0)  / (x1 - x0) + nCeil0),  yTop[x + 1], yLow[x + 1])
                local nfloor = geo.clamp(math.floor((x - x0) * (nFloor1 - nFloor0) / (x1 - x0) + nFloor0), yTop[x + 1], yLow[x + 1])

                -- Render upper and lower walls
                vline(x, ceil,       nceil - 1, {hue, hue, hue}, {0, 0, 0}) -- Upper
                vline(x, nfloor + 1, floor,     {hue, hue, hue}, {0, 0, 0}) -- Lower

                -- Shrink the windows
                yTop[x + 1] = geo.clamp(math.max(ceil,  nceil),  yTop[x + 1], ScreenHeight - 1);
                yLow[x + 1] = geo.clamp(math.min(floor, nfloor), 0,           yLow[x + 1]);
            else
                vline(x, ceil, floor, {hue, hue, hue}, {0, 0, 0})
            end

        end

        -- Schedule neighboring sector
        if next(neighbor) ~= nil and xEnd > xBegin and depth >= 0 then
            drawSector(
                verteces, sectors, camera,
                {
                    sector = neighbor[1] + 1,
                    sx0 = xBegin,
                    sx1 = xEnd
                },
                yTop, yLow,
                depth - 1
            )
        end

        ::continue::
    end
    
end

graphics.drawScreen = function (verteces, sectors, camera)
    -- Prepare screen bounds
    local yTop = {}
    local yLow = {}
    for i = 1, ScreenWidth do
        yTop[i] = 0
        yLow[i] = ScreenHeight - 1
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
end

return graphics