-- Imports
require("constants")
local geo  = require("lib.helpers.geometricFunctions")
local util = require("lib.helpers.utilities")

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

-- Draw scaled pixel
local function drawPixel(x, y, color)
    local R = color[1] / 255
    local G = color[2] / 255
    local B = color[3] / 255

    love.graphics.setColor(R, G, B)
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
local function vline2(x, yTop, yLow, texBoundTop, texBoundLow, tex, txtx, shade, boundTop, boundLow)
    -- Limit the values to valid ranges
    yTop = geo.clamp(yTop, boundTop, boundLow) + 1
    yLow = geo.clamp(yLow, boundTop, boundLow) - 1

    local ty = util.scalerInit(texBoundTop, yTop, texBoundLow, 0, tex.dim.height - 1)

    for y = yTop, yLow do
        -- Texture scaling calculations
        local txty = util.scalerNext(ty)
        local R, G, B, _ = tex.sheet:getPixel(
            -- TODO: Fix UV mapping
            (tex.cords.i * tex.dim.width)  + (txtx * tex.cords.u) % tex.dim.width,
            (tex.cords.j * tex.dim.height) + (txty * tex.cords.v) % tex.dim.height
        )

        drawPixel(x, y, {
            math.max(R * 255 - shade * ShadowIntensity, 0),
            math.max(G * 255 - shade * ShadowIntensity, 0),
            math.max(B * 255 - shade * ShadowIntensity, 0)
        })
    end
end

local function precalcSprite(entity, camera)
    local camCos = math.cos(camera.angle)
    local camSin = math.sin(camera.angle)
    
    local vx = entity.where.x - camera.where.x
    local vy = entity.where.y - camera.where.y

    local tx = vx * camSin - vy * camCos
    local tz = vx * camCos + vy * camSin

    -- Only render if at least partially in front of the camera
    if tz <= 0 then return end

    -- Perspective transformation
    local xScale = (ScreenWidth  * Hfov) / tz
    local yScale = (ScreenHeight * Vfov) / tz
    local x = ScreenWidth / 2 - math.floor(tx * xScale)

    -- Obtain floor and ceiling heights, relative to camera position
    -- TODO: Add crouch detection
    local yHead = entity.where.z - camera.where.z + HeadMargin
    local yFeet = entity.where.z - camera.where.z - EyeHeight

    -- Project ceiling and floor heights onto screen y-coordinate
    local head = ScreenHeight / 2 - math.floor((yHead + tz * camera.pitch) * yScale)
    local feet = ScreenHeight / 2 - math.floor((yFeet + tz * camera.pitch) * yScale)

    local height = head - feet
    local width  = math.floor(height / 3)

    local x0 = x + width
    local x1 = x - width

    -- Only render if visible
    if x1 < 0 or x0 > ScreenWidth - 1 then return else return {tz = tz, head = head, feet = feet, x0 = x0, x1 = x1} end
end

local function drawSprite(precalc, now, yTop, yLow)
    -- x bounds
    local xBegin = math.max(precalc.x0, now.sx0)
    local xEnd   = math.min(precalc.x1, now.sx1)

    for xIter = xBegin, xEnd do
        vline(xIter, precalc.head, precalc.feet, {255, 0, 0}, yTop[1][xIter + 1], yLow[1][xIter + 1])
    end
end

local function drawSector(sectors, textures, camera, now, yTop, yLow, depth, ldep, rdep)
    local sector = sectors[now.sector]

    local camCos = math.cos(camera.angle)
    local camSin = math.sin(camera.angle)

    -- Render each wall
    for s = 1, #sector.nodes do
 
        -- Obtain the coordinates of 2 endpoints of rendered edge
        local vx0 = sector:nodeAt(s + 0).x - camera.where.x
        local vy0 = sector:nodeAt(s + 0).y - camera.where.y
        local vx1 = sector:nodeAt(s + 1).x - camera.where.x
        local vy1 = sector:nodeAt(s + 1).y - camera.where.y

        -- Rotate them around camera's view
        local tx0 = vx0 * camSin - vy0 * camCos
        local tz0 = vx0 * camCos + vy0 * camSin
        local tx1 = vx1 * camSin - vy1 * camCos
        local tz1 = vx1 * camCos + vy1 * camSin

        -- Only render if at least partially in front of the camera
        if tz0 <= 0 and tz1 <= 0 then goto continue end

        -- Clip to view frustrum
        -- local u0 = 0
        -- local u1 = textures.texDim.width - 1

        if tz0 <= 0 or tz1 <= 0 then
            local inter = geo.intersect(
                tx0, tz0, tx1, tz1,
                -1, 0, 1, 0
            )

            -- local org0 = {x = tx0, z = tz0}
            -- local org1 = {x = tx1, z = tz1}

            if tz0 <= 0 then
                tx0 = inter.x
                tz0 = 1e-10
            elseif tz1 <= 0 then
                tx1 = inter.x
                tz1 = 1e-10
            end

            -- u1 is only used for texture width value
            -- if math.abs(tx1 - tx0) > math.abs(tz1 - tz0) then
            --     u0 = (tx0 - org0.x) * u1 / (org1.x - org0.x)
            --     u1 = (tx1 - org0.x) * u1 / (org1.x - org0.x)
            -- else
            --     u0 = (tz0 - org0.z) * u1 / (org1.z - org0.z)
            --     u1 = (tz1 - org0.z) * u1 / (org1.z - org0.z)
            -- end
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
        local yCeil0  = sector:ceil (sector:nodeAt(s + 0)) - camera.where.z
        local yFloor0 = sector:floor(sector:nodeAt(s + 0)) - camera.where.z
        local yCeil1  = sector:ceil (sector:nodeAt(s + 1)) - camera.where.z
        local yFloor1 = sector:floor(sector:nodeAt(s + 1)) - camera.where.z

        -- Choose texture bounds
        -- local tyCeil  = math.max(yCeil0,  yCeil1)
        -- local tyFloor = math.min(yFloor0, yFloor1)

        -- Project ceiling and floor heights onto screen y-coordinate
        local ceilInt  = util.scalerInit(x0, xBegin, x1,
            ScreenHeight / 2 - math.floor((yCeil0 + tz0 * camera.pitch) * yScale0),
            ScreenHeight / 2 - math.floor((yCeil1 + tz1 * camera.pitch) * yScale1)
        )
        local floorInt = util.scalerInit(x0, xBegin, x1,
            ScreenHeight / 2 - math.floor((yFloor0 + tz0 * camera.pitch) * yScale0),
            ScreenHeight / 2 - math.floor((yFloor1 + tz1 * camera.pitch) * yScale1)
        )
        -- local texCeilInt = util.scalerInit(x0, xBegin, x1,
        --     ScreenHeight / 2 - math.floor((tyCeil + tz0 * camera.pitch) * yScale0),
        --     ScreenHeight / 2 - math.floor((tyCeil + tz1 * camera.pitch) * yScale1)
        -- )
        -- local texFloorInt = util.scalerInit(x0, xBegin, x1,
        --     ScreenHeight / 2 - math.floor((tyFloor + tz0 * camera.pitch) * yScale0),
        --     ScreenHeight / 2 - math.floor((tyFloor + tz1 * camera.pitch) * yScale1)
        -- )

        -- Neighbor ceiling and floor
        local neighbor     = sector.links[s]
        local nCeilInt     = {}
        local nFloorInt    = {}
        -- local nTexCeilInt  = {}
        -- local nTexFloorInt = {}
        if next(neighbor) ~= nil then

            for idx, n in ipairs(neighbor) do
               
                -- Obtain floor and ceiling heights, relative to camera position
                local vnCeil0  = sectors[n]:ceil (sector:nodeAt(s + 0)) - camera.where.z
                local vnFloor0 = sectors[n]:floor(sector:nodeAt(s + 0)) - camera.where.z
                local vnCeil1  = sectors[n]:ceil (sector:nodeAt(s + 1)) - camera.where.z
                local vnFloor1 = sectors[n]:floor(sector:nodeAt(s + 1)) - camera.where.z

                -- Choose texture bounds
                -- local tvnCeil  = math.min(vnCeil0,  vnCeil1)
                -- local tvnFloor = math.max(vnFloor0, vnFloor1)

                -- Project ceiling and floor heights onto screen y-coordinate
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
                -- table.insert(
                --     nTexCeilInt,
                --     util.scalerInit(x0, xBegin, x1,
                --         ScreenHeight / 2 - math.floor((tvnCeil + tz0 * camera.pitch) * yScale0),
                --         ScreenHeight / 2 - math.floor((tvnCeil + tz1 * camera.pitch) * yScale1)
                --     )
                -- )
                -- table.insert(
                --     nTexFloorInt,
                --     util.scalerInit(x0, xBegin, x1,
                --         ScreenHeight / 2 - math.floor((tvnFloor + tz0 * camera.pitch) * yScale0),
                --         ScreenHeight / 2 - math.floor((tvnFloor + tz1 * camera.pitch) * yScale1)
                --     )
                -- )

                -- Ensure there is enough yTop, yLow tables
                yTop[idx + 1] = util.shallow(yTop[1])
                yLow[idx + 1] = util.shallow(yLow[1])
            end

        end

        for x = xBegin, xEnd do
            -- Calculate this points z-coordinate for shading

            -- local shader = math.floor((((ScreenWidth / 2) - x) / (ScreenWidth * Hfov)) * 10) * 8

            -- local zShade = math.abs(math.floor(((x - x0) * (tz1 - tz0) / (x1 - x0) + tz0) * 8))
            -- local xShade = math.abs(math.floor(((x - x0) * (tx1 - tx0) / (x1 - x0) + tx0) * 8))
            -- local shader = math.floor(math.sqrt(xShade^2 + zShade^2))
            -- local shader = 0.2

            -- local txtx = (u0 * ((x1 - x) * tz1) + u1 * ((x - x0) * tz0)) / ((x1 - x) * tz1 + (x - x0) * tz0)

            -- Obtain y-coordinate for ceiling and floor for this x-coordinate
            local ceil  = util.scalerNext(ceilInt)
            local floor = util.scalerNext(floorInt)
            -- local tex   = util.scalerNext(texCeilInt)

            -- Render ceiling and floor: everything above and below relevent heights
            vline(x, yTop[1][x + 1], ceil,           {50, 50, 50}, yTop[1][x + 1], yLow[1][x + 1]) -- Ceiling
            vline(x, floor,          yLow[1][x + 1], {50, 50, 50}, yTop[1][x + 1], yLow[1][x + 1]) -- Floor

            -- Render wall: depends if portal or not
            if next(neighbor) ~= nil then
                for idx = 1, #neighbor do
                    local nceil  = util.scalerNext(nCeilInt[idx])
                    local nfloor = util.scalerNext(nFloorInt[idx])
                    -- local ntex   = util.scalerNext(nTexCeilInt[idx])

                    -- Render upper walls
                    if x ~= x0 and x ~= x1 then
                        vline(x, ceil, nceil, {200, 200, 200}, yTop[idx + 1][x + 1], yLow[idx + 1][x + 1])
                        -- vline2(x, ceil, nceil,
                        --     tex, ntex,
                        --     {
                        --         sheet = textures.sheet,
                        --         dim   = textures.texDim,
                        --         cords = textures.sector[now.sector][s][idx]
                        --     },
                        --     txtx, shader,
                        --     yTop[idx + 1][x + 1], yLow[idx + 1][x + 1]
                        -- )
                    end
                    
                    -- Shrink the windows
                    yTop[idx + 1][x + 1] = geo.clamp(math.max(ceil,  nceil),  yTop[idx + 1][x + 1], ScreenHeight)
                    yLow[idx + 1][x + 1] = geo.clamp(math.min(floor, nfloor), -1,                   yLow[idx + 1][x + 1])

                    ceil = nfloor
                    -- tex  = util.scalerNext(nTexFloorInt[idx])
                end

                -- Render lowest wall
                if x ~= x0 and x ~= x1 then
                    vline(x, ceil, floor, {200, 200, 200}, yTop[1][x + 1], yLow[1][x + 1])
                    -- vline2(x, ceil, floor,
                    --     tex, util.scalerNext(texFloorInt),
                    --     {
                    --         sheet = textures.sheet,
                    --         dim   = textures.texDim,
                    --         cords = textures.sector[now.sector][s][#neighbor + 1]
                    --     },
                    --     txtx, shader,
                    --     yTop[1][x + 1], yLow[1][x + 1]
                    -- )
                end
                
            elseif x ~= x0 and x ~= x1 then
                vline(x, ceil, floor, {200, 200, 200}, yTop[1][x + 1], yLow[1][x + 1])
                -- vline2(x, ceil, floor,
                --     tex, util.scalerNext(texFloorInt),
                --     {
                --         sheet = textures.sheet,
                --         dim   = textures.texDim,
                --         cords = textures.sector[now.sector][s][1]
                --     },
                --     txtx, shader,
                --     yTop[1][x + 1], yLow[1][x + 1]
                -- )
            end
        end

        -- Schedule neighboring sector
        if next(neighbor) ~= nil and xEnd > xBegin and depth >= 0 then
            for idx = 1, #neighbor do
                local passed = drawSector(
                    sectors, textures, camera,
                    {
                        sector = neighbor[idx],
                        sx0 = xBegin,
                        sx1 = xEnd
                    },
                    {yTop[idx + 1]}, {yLow[idx + 1]},
                    depth - 1, tz0, tz1
                )
                sector.precalcs = util.mergeArrayTables(sector.precalcs, passed)
            end
        end

        ::continue::
    end

    local forwarded = {}
    -- Draw sprites
    for i = 1, #sector.precalcs do
        if sector.precalcs[i].tz < ldep then
            table.insert(forwarded, {
                tz = sector.precalcs[i].tz,
                head = sector.precalcs[i].head,
                feet = sector.precalcs[i].feet,
                x0 = sector.precalcs[i].x0,
                x1 = now.sx1
            })
        elseif sector.precalcs[i].tz < rdep then
            table.insert(forwarded, {
                tz = sector.precalcs[i].tz,
                head = sector.precalcs[i].head,
                feet = sector.precalcs[i].feet,
                x0 = now.sx0,
                x1 = sector.precalcs[i].x1
            })
        else
            drawSprite(sector.precalcs[i], now, yTop, yLow)
        end
    end

    return forwarded

end

graphics.drawScreen = function (sectors, entities, textures, camera)
    -- Prepare sprites
    -- TODO: sorting by depth
    for idx, ent in ipairs(entities) do
        local precalc = precalcSprite(ent, camera)
        if precalc then
            precalc.idx = idx
            table.insert(sectors[ent.sector].precalcs, precalc)
        end 
    end

    -- Prepare screen bounds
    local yTop = {{}}
    local yLow = {{}}
    for i = 1, ScreenWidth do
        yTop[1][i] = -1
        yLow[1][i] = ScreenHeight
    end

    -- Begin from camera
    drawSector(
        sectors, textures, camera,
        {
            sector = camera.sector,
            sx0 = 0,
            sx1 = ScreenWidth - 1
        },
        yTop, yLow,
        RenderDepth, 0, 0
    )

    drawCenteredText(540, 10, 30, 25, camera.sector)
    drawCenteredText(520, 45, 30, 25, camera.where.x)
    drawCenteredText(520, 75, 30, 25, camera.where.y)

    -- Cleanup
    for i = 1, #sectors do
        sectors[i].precalcs = {}
    end
end

return graphics