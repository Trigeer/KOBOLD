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
local function vline(x, yTop, yLow, color, texH, shade, boundTop, boundLow)
    local yTopCopy = yTop

    local texV  = 0
    local stepV = texDim.height / (yLow - yTop)

    -- Limit the values to valid ranges
    x = math.abs(x)
    yTop = geo.clamp(yTop, boundTop, boundLow) + 1
    yLow = geo.clamp(yLow, boundTop, boundLow) - 1

    if yTopCopy < yTop-1 then texV = texV + (stepV * (yTop - yTopCopy)) end

    for y = yTop, yLow do
        if texH == -1 then
            drawPixel(x, y, color)
        else
            local pixel = {texV % texDim.height, texH % texDim.width}
            local r = math.max(texture:getPixel(pixel[2], pixel[1]) * 255, 0) - shade/2
            local g = math.max(texture:getPixel(pixel[2], pixel[1]) * 255, 0) - shade/2
            local b = math.max(texture:getPixel(pixel[2], pixel[1]) * 255, 0) - shade/2
            drawPixel(x, y, {r, g, b})
            texV = texV + stepV
        end
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
        if tz0 < near and tz1 < near then goto continue end
        -- Clip against view frustrum
        if tz0 < near or tz1 < near then
            -- Calculate intersection point
            local inter = geo.intersect(geo.intercheck(
                    tx0, tz0, tx1, tz1,
                    -1, near,
                    1, near
                ).uAB, tx0, tz0, tx1, tz1
            )
            if tz0 < near then
                tx0 = inter.x
                tz0 = near
            elseif tz1 < near then
                tx1 = inter.x
                tz1 = near
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

        -- print(tz0 .. " " .. xScale0 .. " " .. x0)

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
        local nCeil0  = {}
        local nFloor0 = {}
        local nCeil1  = {}
        local nFloor1 = {}
        if next(neighbor) ~= nil then

            for idx, n in pairs(neighbor) do
               
                -- Obtain floor and ceiling heights, relative to camera position
                local nCeil  = sectors[n + 1].ceil  - camera.where.z
                local nFloor = sectors[n + 1].floor - camera.where.z

                -- Project ceiling and floor heights onto screen y-coordinate
                table.insert(nCeil0,  math.floor(ScreenHeight / 2) - math.floor((nCeil  + tz0 * camera.pitch) * yScale0))
                table.insert(nFloor0, math.floor(ScreenHeight / 2) - math.floor((nFloor + tz0 * camera.pitch) * yScale0))
                table.insert(nCeil1,  math.floor(ScreenHeight / 2) - math.floor((nCeil  + tz1 * camera.pitch) * yScale1))
                table.insert(nFloor1, math.floor(ScreenHeight / 2) - math.floor((nFloor + tz1 * camera.pitch) * yScale1))

                -- Ensure there is enough yTop, yLow tables
                yTop[idx + 1] = util.shallow(yTop[1])
                yLow[idx + 1] = util.shallow(yLow[1])

            end

        end

        -- Render the wall
        local xBegin = math.max(x0, now.sx0)
        local xEnd   = math.min(x1, now.sx1)

        -- Calculate texture horizontal values
        local texH  = 0
        local stepH = texDim.width * 2 / (x1 - x0)
        if x0 < xBegin then texH = stepH * (xBegin - x0) end

        for x = xBegin, xEnd do
            -- Calculate this points z-coordinate for shading
            local zShade = math.abs(math.floor(((x - x0) * (tz1 - tz0) / (x1 - x0) + tz0) * 8))
            local xShade = math.abs(math.floor(((x - x0) * (tx1 - tx0) / (x1 - x0) + tx0) * 8))
            local shader = math.floor(math.sqrt(xShade^2 + zShade^2))

            -- Obtain y-coordinate for ceiling and floor for this x-coordinate
            -- TODO: Change to stepped values
            local ceil  = math.floor((x - x0) * (yCeil1  - yCeil0)  / (x1 - x0) + yCeil0)
            local floor = math.floor((x - x0) * (yFloor1 - yFloor0) / (x1 - x0) + yFloor0)

            -- Render ceiling and floor: everything above and below relevent heights
            vline(x, yTop[1][x + 1], ceil,       {50, 50, 50}, -1, 0, yTop[1][x + 1], yLow[1][x + 1]) -- Ceiling
            vline(x, floor,      yLow[1][x + 1], {50, 50, 50}, -1, 0, yTop[1][x + 1], yLow[1][x + 1]) -- Floor

            -- Set the color
            local hue = 255 - shader

            -- Render wall: depends if portal or not
            if next(neighbor) ~= nil then
                for idx = 1, #neighbor do
                    -- TODO: change to stepped values
                    local nceil  = math.floor((x - x0) * (nCeil1[idx]  - nCeil0[idx])  / (x1 - x0) + nCeil0[idx])
                    local nfloor = math.floor((x - x0) * (nFloor1[idx] - nFloor0[idx]) / (x1 - x0) + nFloor0[idx])

                    -- Render upper walls
                    if x ~= x0 and x ~= x1 then
                        vline(x, ceil, nceil, {hue, hue, hue}, texH, shader, yTop[idx + 1][x + 1], yLow[idx + 1][x + 1])
                    end
                    
                    -- Shrink the windows
                    yTop[idx + 1][x + 1] = geo.clamp(math.max(ceil,  nceil),  yTop[idx + 1][x + 1], ScreenHeight)
                    yLow[idx + 1][x + 1] = geo.clamp(math.min(floor, nfloor), -1,               yLow[idx + 1][x + 1])

                    ceil = nfloor
                end

                -- Render lowest wall
                if x ~= x0 and x ~= x1 then
                    vline(x, ceil, floor, {hue, hue, hue}, texH, shader, yTop[1][x + 1], yLow[1][x + 1])
                end
                
            elseif x ~= x0 and x ~= x1 then
                vline(x, ceil, floor, {hue, hue, hue}, texH, shader, yTop[1][x + 1], yLow[1][x + 1])
            end

            texH = texH + stepH
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