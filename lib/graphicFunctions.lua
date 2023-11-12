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

-- local texture = love.image.newImageData("textures/Textures-16.png")
-- local textureIndex = {x = 12, y = 10}
-- local texDim  = {width = 16, height = 16}
-- local uvMap   = {u = 2, v = 2}

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
local function vline(x, yTop, yLow, color, boundTop, boundLow)
    -- Limit the values to valid ranges
    yTop = geo.clamp(yTop, boundTop, boundLow) + 1
    yLow = geo.clamp(yLow, boundTop, boundLow) - 1

    for y = yTop, yLow do
        drawPixel(x, y, color)
    end
end

-- Textured vertical line
local function vline2(x, yTop, yLow, tex, txtx, shade, boundTop, boundLow)
    -- Save original values
    local orgTop = yTop
    local orgLow = yLow

    -- Limit the values to valid ranges
    -- x = math.abs(x)
    yTop = geo.clamp(yTop, boundTop, boundLow) + 1
    yLow = geo.clamp(yLow, boundTop, boundLow) - 1

    local ty = util.scalerInit(orgTop, yTop, orgLow, 0, tex.dim.height - 1)

    for y = yTop, yLow do
        -- Texture scaling calculations
        local txty = util.scalerNext(ty)
        local r, g, b, _ = tex.sheet:getPixel(
            (tex.cords.i * tex.dim.width)  + (txtx * tex.cords.u) % tex.dim.width,
            (tex.cords.j * tex.dim.height) + (txty * tex.cords.v) % tex.dim.height
        )

        drawPixel(x, y, {
            math.max(r * 255 - shade * ShadowIntensity, 0),
            math.max(g * 255 - shade * ShadowIntensity, 0),
            math.max(b * 255 - shade * ShadowIntensity, 0)
        })
    end
end

local function drawSector(verteces, sectors, textures, camera, now, yTop, yLow, depth)
    local sector = sectors[now.sector]

    local camCos = math.cos(camera.angle)
    local camSin = math.sin(camera.angle)

    -- Save sector's origin
    local xOrigin = verteces[sector.vertex[1] + 1].x - camera.where.x
    local zOrigin = verteces[sector.vertex[1] + 1].y - camera.where.y

    -- Render each wall
    for s = 1, #sector.vertex - 1 do
 
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
        if tz0 <= Near and tz1 <= Near then goto continue end

        -- Clip to view frustrum
        local u0 = 0
        local u1 = textures.texDim.width - 1

        if tz0 <= Near or tz1 <= Near then
            local inter = geo.intersect(geo.intercheck(
                tx0, tz0, tx1, tz1,
                -1, Near,
                1, Near
            ).uAB, tx0, tz0, tx1, tz1)

            local org0 = {x = tx0, z = tz0}
            local org1 = {x = tx1, z = tz1}

            if tz0 < Near then
                tx0 = inter.x
                tz0 = inter.y
            elseif tz1 < Near then
                tx1 = inter.x
                tz1 = inter.y
            end

            -- u1 is only used for texture width value
            if math.abs(tx1 - tx0) > math.abs(tz1 - tz0) then
                u0 = (tx0 - org0.x) * u1 / (org1.x - org0.x)
                u1 = (tx1 - org0.x) * u1 / (org1.x - org0.x)
            else
                u0 = (tz0 - org0.z) * u1 / (org1.z - org0.z)
                u1 = (tz1 - org0.z) * u1 / (org1.z - org0.z)
            end
        end

        -- Perspective transformation
        local xScale0 = (ScreenWidth  * Hfov) / tz0
        local yScale0 = (ScreenHeight * Vfov) / tz0
        local xScale1 = (ScreenWidth  * Hfov) / tz1
        local yScale1 = (ScreenHeight * Vfov) / tz1
        local x0 = ScreenWidth / 2 - math.floor(tx0 * xScale0)
        local x1 = ScreenWidth / 2 - math.floor(tx1 * xScale1)
        -- Only render if visible
        if x0 >= x1 or x1 < now.sx0 or x0 > now.sx1 then goto continue end

        -- x bounds
        local xBegin = math.max(x0, now.sx0)
        local xEnd   = math.min(x1, now.sx1)

        -- Obtain floor and ceiling heights, relative to camera position
        local yCeil0  = geo.planeZ(sector.ceil, xOrigin, zOrigin, vx0, vy0)  - camera.where.z
        local yFloor0 = geo.planeZ(sector.floor, xOrigin, zOrigin, vx0, vy0) - camera.where.z
        local yCeil1  = geo.planeZ(sector.ceil, xOrigin, zOrigin, vx1, vy1)  - camera.where.z
        local yFloor1 = geo.planeZ(sector.floor, xOrigin, zOrigin, vx1, vy1) - camera.where.z

        -- Project ceiling and floor heights onto screen y-coordinate
-- <<<<<<< HEAD
        local ceilInt  = util.scalerInit(x0, xBegin, x1,
            ScreenHeight / 2 - math.floor((yCeil0 + tz0 * camera.pitch) * yScale0),
            ScreenHeight / 2 - math.floor((yCeil1 + tz1 * camera.pitch) * yScale1)
        )
        local floorInt = util.scalerInit(x0, xBegin, x1,
            ScreenHeight / 2 - math.floor((yFloor0 + tz0 * camera.pitch) * yScale0),
            ScreenHeight / 2 - math.floor((yFloor1 + tz1 * camera.pitch) * yScale1)
        )
-- =======
--         yCeil0  = math.floor(ScreenHeight / 2) - math.floor((yCeil0  + tz0 * camera.pitch) * yScale0)
--         yFloor0 = math.floor(ScreenHeight / 2) - math.floor((yFloor0 + tz0 * camera.pitch) * yScale0)
--         yCeil1  = math.floor(ScreenHeight / 2) - math.floor((yCeil1  + tz1 * camera.pitch) * yScale1)
--         yFloor1 = math.floor(ScreenHeight / 2) - math.floor((yFloor1 + tz1 * camera.pitch) * yScale1)
-- >>>>>>> Feature-5-Crooked

        -- Neighbor ceiling and floor
        local neighbor = sector.neighbor[s]
        local nCeilInt  = {}
        local nFloorInt = {}
        if next(neighbor) ~= nil then

            for idx, n in pairs(neighbor) do

                -- Get neighbor's origin
                local nxOrigin = verteces[sectors[n + 1].vertex[1] + 1].x - camera.where.x
                local nzOrigin = verteces[sectors[n + 1].vertex[1] + 1].y - camera.where.y
               
                -- Obtain floor and ceiling heights, relative to camera position
                local vnCeil0  = geo.planeZ(sectors[n + 1].ceil, nxOrigin, nzOrigin, vx0, vy0)  - camera.where.z
                local vnFloor0 = geo.planeZ(sectors[n + 1].floor, nxOrigin, nzOrigin, vx0, vy0) - camera.where.z
                local vnCeil1  = geo.planeZ(sectors[n + 1].ceil, nxOrigin, nzOrigin, vx1, vy1)  - camera.where.z
                local vnFloor1 = geo.planeZ(sectors[n + 1].floor, nxOrigin, nzOrigin, vx1, vy1) - camera.where.z

                -- Project ceiling and floor heights onto screen y-coordinate
-- <<<<<<< HEAD
                table.insert(
                    nCeilInt,
                    util.scalerInit(x0, xBegin, x1,
                        ScreenHeight / 2 - math.floor((vnCeil0 + tz0 * camera.pitch) * yScale0),
                        ScreenHeight / 2 - math.floor((vnCeil1 + tz1 * camera.pitch) * yScale1)
                    )
                )
                table.insert(
                    nFloorInt,
                    util.scalerInit(x0, xBegin, x1,
                        ScreenHeight / 2 - math.floor((vnFloor0 + tz0 * camera.pitch) * yScale0),
                        ScreenHeight / 2 - math.floor((vnFloor1 + tz1 * camera.pitch) * yScale1)
                    )
                )
-- =======
--                 table.insert(nCeil0,  math.floor(ScreenHeight / 2) - math.floor((vnCeil0  + tz0 * camera.pitch) * yScale0))
--                 table.insert(nFloor0, math.floor(ScreenHeight / 2) - math.floor((vnFloor0 + tz0 * camera.pitch) * yScale0))
--                 table.insert(nCeil1,  math.floor(ScreenHeight / 2) - math.floor((vnCeil1  + tz1 * camera.pitch) * yScale1))
--                 table.insert(nFloor1, math.floor(ScreenHeight / 2) - math.floor((vnFloor1 + tz1 * camera.pitch) * yScale1))
-- >>>>>>> Feature-5-Crooked

                -- Ensure there is enough yTop, yLow tables
                yTop[idx + 1] = util.shallow(yTop[1])
                yLow[idx + 1] = util.shallow(yLow[1])
            end

        end

        for x = xBegin, xEnd do
            -- Calculate this points z-coordinate for shading
            local zShade = math.abs(math.floor(((x - x0) * (tz1 - tz0) / (x1 - x0) + tz0) * 8))
            local xShade = math.abs(math.floor(((x - x0) * (tx1 - tx0) / (x1 - x0) + tx0) * 8))
            local shader = math.floor(math.sqrt(xShade^2 + zShade^2))

            local txtx = (u0 * ((x1 - x) * tz1) + u1 * ((x - x0) * tz0)) / ((x1 - x) * tz1 + (x - x0) * tz0)

            -- Obtain y-coordinate for ceiling and floor for this x-coordinate
            local ceil  = util.scalerNext(ceilInt)
            local floor = util.scalerNext(floorInt)

            -- Render ceiling and floor: everything above and below relevent heights
            vline(x, yTop[1][x + 1], ceil,           {50, 50, 50}, yTop[1][x + 1], yLow[1][x + 1]) -- Ceiling
            vline(x, floor,          yLow[1][x + 1], {50, 50, 50}, yTop[1][x + 1], yLow[1][x + 1]) -- Floor

            -- Render wall: depends if portal or not
            if next(neighbor) ~= nil then
                for idx = 1, #neighbor do
                    local nceil  = util.scalerNext(nCeilInt[idx])
                    local nfloor = util.scalerNext(nFloorInt[idx])

                    -- Render upper walls
                    if x ~= x0 and x ~= x1 then
                        vline2(x, ceil, nceil,
                            {
                                sheet = textures.sheet,
                                dim = textures.texDim,
                                cords = textures.sector[now.sector][s][idx]
                            },
                            txtx, shader,
                            yTop[idx + 1][x + 1], yLow[idx + 1][x + 1]
                        )
                    end
                    
                    -- Shrink the windows
                    yTop[idx + 1][x + 1] = geo.clamp(math.max(ceil,  nceil),  yTop[idx + 1][x + 1], ScreenHeight)
                    yLow[idx + 1][x + 1] = geo.clamp(math.min(floor, nfloor), -1,                   yLow[idx + 1][x + 1])

                    ceil = nfloor
                end

                -- Render lowest wall
                if x ~= x0 and x ~= x1 then
                    vline2(x, ceil, floor,
                        {
                            sheet = textures.sheet,
                            dim = textures.texDim,
                            cords = textures.sector[now.sector][s][#neighbor + 1]
                        },
                        txtx, shader,
                        yTop[1][x + 1], yLow[1][x + 1]
                    )
                end
                
            elseif x ~= x0 and x ~= x1 then
                vline2(x, ceil, floor,
                    {
                        sheet = textures.sheet,
                        dim = textures.texDim,
                        cords = textures.sector[now.sector][s][1]
                    },
                    txtx, shader,
                    yTop[1][x + 1], yLow[1][x + 1]
                )
            end
        end

        -- Schedule neighboring sector
        if next(neighbor) ~= nil and xEnd > xBegin and depth >= 0 then
            for idx = 1, #neighbor do
                drawSector(
                verteces, sectors, textures, camera,
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

graphics.drawScreen = function (verteces, sectors, textures, camera)
    -- Prepare screen bounds
    local yTop = {{}}
    local yLow = {{}}
    for i = 1, ScreenWidth do
        yTop[1][i] = -1
        yLow[1][i] = ScreenHeight
    end

    -- Begin from camera
    drawSector(
        verteces, sectors, textures, camera,
        {
            sector = camera.sector + 1,
            sx0 = 0,
            sx1 = ScreenWidth - 1
        },
        yTop, yLow,
        RenderDepth
    )

    drawCenteredText(540, 10, 30, 25, camera.sector)
end

return graphics