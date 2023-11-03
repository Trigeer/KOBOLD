-- Imports
require("constants")
local geo  = require("lib.geometricFunctions")
local util = require("lib.utilities")

local graphics = {}

local function drawCenteredText(rectX, rectY, rectWidth, rectHeight, text)
	local font       = love.graphics.getFont()
	local textWidth  = font:getWidth(text)
	local textHeight = font:getHeight()
    love.graphics.setColor({0, 0, 0})
    love.graphics.rectangle("fill", rectX, rectY, rectWidth, rectHeight)
    love.graphics.setColor({1, 1, 1})
	love.graphics.print(text, rectX+rectWidth/2, rectY+rectHeight/2, 0, 1, 1, textWidth/2, textHeight/2)
end

local texture = love.image.newImageData("textures/stone.png")
local texDim  = {width = 16, height = 16}
-- local uvMap   = {u = 1, v = 1}

-- Draw scaled pixel
local function drawPixel(x, y, color)
    local red   = color[1] / 255
    local green = color[2] / 255
    local blue  = color[3] / 255

    love.graphics.setColor(red, green, blue)
    love.graphics.rectangle(
        "fill",
        x * Scaling,
        y * Scaling,
        Scaling, Scaling
    )
end

-- A custom line method
local function vline(x, yTop, yLow, color, shade, boundTop, boundLow)
    -- Limit the values to valid ranges
    -- x = math.abs(x)
    yTop = geo.clamp(yTop, boundTop, boundLow) + 1
    yLow = geo.clamp(yLow, boundTop, boundLow) - 1

    for y = yTop, yLow do
        drawPixel(x, y, color)
    end
end

local function vline2(x, yTop, yLow, ty, txtx, shade, boundTop, boundLow)
    yTop = geo.clamp(yTop, boundTop, boundLow) + 1
    yLow = geo.clamp(yLow, boundTop, boundLow) - 1

    for y = yTop, yLow do
        local txty = geo.scalerNext(ty)
        local r, g, b, _ = texture:getPixel(txtx % texDim.width, txty % texDim.height)
        drawPixel(x, y, {
            math.max(r * 255 - shade / 2, 0),
            math.max(g * 255 - shade / 2, 0),
            math.max(b * 255 - shade / 2, 0)
        })
    end
end

local function drawSector(verteces, sectors, camera, now, yTop, yLow, depth)
    local sector = sectors[now.sector]

    local camCos = math.cos(camera.angle)
    local camSin = math.sin(camera.angle)

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
        if tz0 <= 0 and tz1 <= 0 then goto continue end

        -- Clip to view frustrum
        local u0 = 0
        local u1 = 15

        if tz0 <= 0 or tz1 <= 0 then
            local nearz = 1e-4
            local farz  = 5
            local nearside = 1e-5
            local farside  = 20

            local inter0 = geo.intersect(geo.intercheck(tx0, tz0, tx1, tz1, -nearside, nearz, -farside, farz).uAB, tx0, tz0, tx1, tz1)
            local inter1 = geo.intersect(geo.intercheck(tx0, tz0, tx1, tz1,  nearside, nearz,  farside, farz).uAB, tx0, tz0, tx1, tz1)

            local original0 = {x = tx0, z = tz0}
            local original1 = {x = tx1, z = tz1}

            if tz0 < nearz then
                if inter0.y > 0 then
                    tx0 = inter0.x
                    tz0 = inter0.y
                else
                    tx0 = inter1.x
                    tz0 = inter1.y
                end
            else
                if inter0.y > 0 then
                    tx1 = inter0.x
                    tz1 = inter0.y
                else
                    tx1 = inter1.x
                    tz1 = inter1.y
                end
            end

            if math.abs(tx1 - tx0) > math.abs(tz1 - tz0) then
                u0 = (tx0 - original0.x) * 15 / (original1.x - original0.x)
                u1 = (tx1 - original0.x) * 15 / (original1.x - original0.x)
            else
                u0 = (tz0 - original0.z) * 15 / (original1.z - original0.z)
                u1 = (tz1 - original0.z) * 15 / (original1.z - original0.z)
            end
        end

        -- Perspective transformation
        local xScale0 = (ScreenWidth  * Hfov) / tz0
        local yScale0 = (ScreenHeight * Vfov) / tz0
        local xScale1 = (ScreenWidth  * Hfov) / tz1
        local yScale1 = (ScreenHeight * Vfov) / tz1
        local x0 = ScreenWidth / 2 - math.floor(-tx0 * xScale0)
        local x1 = ScreenWidth / 2 - math.floor(-tx1 * xScale1)
        -- Only render if visible
        if x0 >= x1 or x1 < now.sx0 or x0 > now.sx1 then goto continue end

        -- x bounds
        local xBegin = math.max(x0, now.sx0)
        local xEnd   = math.min(x1, now.sx1)

        -- Obtain floor and ceiling heights, relative to camera position
        local yCeil  = sector.ceil  - camera.where.z
        local yFloor = sector.floor - camera.where.z

        -- Project ceiling and floor heights onto screen y-coordinate
        local ceilInt  = geo.scalerInit(x0, xBegin, x1,
            ScreenHeight / 2 - math.floor(-(yCeil  + tz0 * camera.pitch) * yScale0),
            ScreenHeight / 2 - math.floor(-(yCeil  + tz1 * camera.pitch) * yScale1)
        )
        local floorInt = geo.scalerInit(x0, xBegin, x1,
            ScreenHeight / 2 - math.floor(-(yFloor + tz0 * camera.pitch) * yScale0),
            ScreenHeight / 2 - math.floor(-(yFloor + tz1 * camera.pitch) * yScale1)
        )

        -- Neighbor ceiling and floor
        local neighbor = sector.neighbor[s]
        local nCeilInt  = {}
        local nFloorInt = {}
        if next(neighbor) ~= nil then

            for idx, n in pairs(neighbor) do
               
                -- Obtain floor and ceiling heights, relative to camera position
                local nCeil  = sectors[n + 1].ceil  - camera.where.z
                local nFloor = sectors[n + 1].floor - camera.where.z

                -- Project ceiling and floor heights onto screen y-coordinate
                table.insert(
                    nCeilInt,
                    geo.scalerInit(x0, xBegin, x1,
                        ScreenHeight / 2 - math.floor(-(nCeil  + tz0 * camera.pitch) * yScale0),
                        ScreenHeight / 2 - math.floor(-(nCeil  + tz1 * camera.pitch) * yScale1)
                    )
                )
                table.insert(
                    nFloorInt,
                    geo.scalerInit(x0, xBegin, x1,
                        ScreenHeight / 2 - math.floor(-(nFloor + tz0 * camera.pitch) * yScale0),
                        ScreenHeight / 2 - math.floor(-(nFloor + tz1 * camera.pitch) * yScale1)
                    )
                )

                -- Ensure there is enough yTop, yLow tables
                yTop[idx + 1] = util.shallow(yTop[1])
                yLow[idx + 1] = util.shallow(yLow[1])
            end

        end

        for x = xBegin, xEnd do
            -- Calculate this points z-coordinate for shading
            -- local zShade = math.abs(math.floor(((x - x0) * (tz1 - tz0) / (x1 - x0) + tz0) * 8))
            -- local xShade = math.abs(math.floor(((x - x0) * (tx1 - tx0) / (x1 - x0) + tx0) * 8))
            -- local shader = math.floor(math.sqrt(xShade^2 + zShade^2))

            local txtx = (u0 * ((x1 - x) * tz1) + u1 * ((x - x0) * tz0)) / ((x1 - x) * tz1 + (x - x0) * tz0)

            -- Obtain y-coordinate for ceiling and floor for this x-coordinate
            local ceil  = geo.scalerNext(ceilInt)
            local floor = geo.scalerNext(floorInt)

            -- Render ceiling and floor: everything above and below relevent heights
            vline(x, yTop[1][x + 1], ceil,       {50, 50, 50}, 0, yTop[1][x + 1], yLow[1][x + 1]) -- Ceiling
            vline(x, floor,      yLow[1][x + 1], {50, 50, 50}, 0, yTop[1][x + 1], yLow[1][x + 1]) -- Floor

            -- Render wall: depends if portal or not
            if next(neighbor) ~= nil then
                for idx = 1, #neighbor do
                    local nceil  = geo.scalerNext(nCeilInt[idx])
                    local nfloor = geo.scalerNext(nFloorInt[idx])

                    -- Render upper walls
                    if x ~= x0 and x ~= x1 then
                        vline2(x, ceil, nceil, geo.scalerInit(ceil, nceil, floor, 0, 15), txtx, 0, yTop[idx + 1][x + 1], yLow[idx + 1][x + 1])
                    end
                    
                    -- Shrink the windows
                    yTop[idx + 1][x + 1] = geo.clamp(math.max(ceil,  nceil),  yTop[idx + 1][x + 1], ScreenHeight)
                    yLow[idx + 1][x + 1] = geo.clamp(math.min(floor, nfloor), -1,                   yLow[idx + 1][x + 1])

                    ceil = nfloor
                end

                -- Render lowest wall
                if x ~= x0 and x ~= x1 then
                    vline2(x, ceil, floor, geo.scalerInit(ceil, nceil, floor, 0, 15), txtx, 0, yTop[1][x + 1], yLow[1][x + 1])
                end
                
            elseif x ~= x0 and x ~= x1 then
                vline2(x, ceil, floor, geo.scalerInit(ceil, nceil, floor, 0, 15), txtx, 0, yTop[1][x + 1], yLow[1][x + 1])
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
                {yTop[idx + 1]}, {yLow[idx + 1]},
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