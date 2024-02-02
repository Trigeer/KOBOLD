require("constants")
local geo  = require("lib.helpers.geometricFunctions")
local util = require("lib.helpers.utilities")

local mov = {}

local function updateVelocity(camera, timeDelta, jump, w, s, a, d)
    -- Jumping
    if jump and camera.grounded then
        camera.velocity.z = 0.7
        camera.grounded = false
    end

    -- Apply key presses
    local camSin = math.sin(camera.angle)
    local camCos = math.cos(camera.angle)
    local mod = {ws = 0, ad = 0}
    if w and not s then mod.ws = 1 elseif not w and s then mod.ws = -1 end
    if a and not d then mod.ad = 1 elseif not a and d then mod.ad = -1 end
    local moveVector = {
        x = mod.ws * camCos + mod.ad * camSin,
        y = mod.ws * camSin - mod.ad * camCos
    }

    local decay = DecayTop
    if w or s or a or d then decay = DecayLow end

    -- New velocity
    camera.velocity.x = (camera.velocity.x * decay + moveVector.x * Speed) * timeDelta
    camera.velocity.y = (camera.velocity.y * decay + moveVector.y * Speed) * timeDelta
end

-- Bounds indicate floor and ceiling height
local function collideVertical(bounds, camera, timeDelta, eyes)
    -- Gravity
    camera.velocity.z = camera.velocity.z - 0.05 * timeDelta
    local next = camera.where.z + camera.velocity.z

    -- TODO: Investigate risk of vertical OOB due too wrong z-velocity direction

    -- Snap to ground
    if camera.velocity.z < 0 and next < bounds.floor + eyes then
        camera.where.z    = bounds.floor + eyes
        camera.velocity.z = 0
        camera.grounded   = true
    -- Ceiling bump
    elseif camera.velocity.z > 0 and next > bounds.ceil - HeadMargin then
        camera.where.z    = bounds.ceil - HeadMargin
        camera.velocity.z = 0
    else
        camera.where.z = next
    end
end

local function collideHorizontal(sectorArr, vertexArr, camera, eyes)
    local checkAgainst = {camera.sector}
    
    camera.where.x = camera.where.x + camera.velocity.x
    camera.where.y = camera.where.y + camera.velocity.y

    -- Calculate camera bounds
    local cameraTop = camera.where.z + HeadMargin
    local cameraMid = camera.where.z - eyes + KneeHeight
    
    for _, sec in pairs(checkAgainst) do
        local sector   = sectorArr[sec + 1]
        local collider = sector.vertex

        for idx = 1, #sector.vertex - 1 do
            local x1 = vertexArr[collider[idx + 0].idx + 1].x
            local y1 = vertexArr[collider[idx + 0].idx + 1].y
            local x2 = vertexArr[collider[idx + 1].idx + 1].x
            local y2 = vertexArr[collider[idx + 1].idx + 1].y

            local xDelta = x2 - x1
            local yDelta = y2 - y1

            -- Player and wall difference
            local pdx = camera.where.x - x1
            local pdy = camera.where.y - y1
            local d = (xDelta * pdx + yDelta * pdy) / (xDelta^2 + yDelta^2)

            -- Skip on too far
            local ends = WallOffset / math.sqrt(xDelta^2 + yDelta^2)
            if 0 - ends > d or d > 1 + ends then goto continue end

            local dx   = d * xDelta + x1
            local dy   = d * yDelta + y1
            local dist = math.sqrt((dx - camera.where.x)^2 + (dy - camera.where.y)^2)
            local crossP = geo.vxp(xDelta, yDelta, pdx, pdy)

            if dist < WallOffset or crossP <= 0 then
                local neighbors = sector.neighbor[idx]

                if next(neighbors) ~= nil then
                    -- Calculate local sector heights
                    local holeLow = geo.planeZ(
                        sector.floor,
                        vertexArr[collider[1].idx + 1].x,
                        vertexArr[collider[1].idx + 1].y,
                        dx, dy
                    )
                    local holeTop = geo.planeZ(
                        sector.ceil,
                        vertexArr[collider[1].idx + 1].x,
                        vertexArr[collider[1].idx + 1].y,
                        dx, dy
                    )

                    for _, neighbor in pairs(neighbors) do

                        local boundLow = math.max(
                            holeLow,
                            geo.planeZ(
                                sectorArr[neighbor + 1].floor,
                                vertexArr[sectorArr[neighbor + 1].vertex[1].idx + 1].x,
                                vertexArr[sectorArr[neighbor + 1].vertex[1].idx + 1].y,
                                dx, dy
                            )
                        )
                        local boundTop = math.min(
                            holeTop,
                            geo.planeZ(
                                sectorArr[neighbor + 1].ceil,
                                vertexArr[sectorArr[neighbor + 1].vertex[1].idx + 1].x,
                                vertexArr[sectorArr[neighbor + 1].vertex[1].idx + 1].y,
                                dx, dy
                            )
                        )

                        if boundTop - boundLow >= eyes + HeadMargin and boundLow <= cameraMid and boundTop >= cameraTop then
                            if not util.table_contains(checkAgainst, neighbor) then
                                table.insert(checkAgainst, neighbor)
                            end
                            goto continue
                        end
                    end
                end

                camera.where.x = d * xDelta + x1 - collider[idx].dx * WallOffset
                camera.where.y = d * yDelta + y1 - collider[idx].dy * WallOffset
            end

        ::continue::
        end
    end

    for _, sec in pairs(checkAgainst) do
        if geo.checkInside(vertexArr, sectorArr[sec + 1], camera) then
            camera.sector = sec
            break
        end
    end
end

mov.moveCamera = function (camera, xDelta, yDelta)
    camera.angle = camera.angle + xDelta * xMouseSensitivity
    camera.pitch = geo.clamp(camera.pitch + yDelta * yMouseSensitivity, -5, 5)
end

-- Locked to assumed 60 FPS
mov.calculateMove = function (sectorArr, vertexArr, camera, timeDelta, jump, crouch, w, s, a, d)
    local eyes = 0
    if crouch then eyes = DuckHeight else eyes = EyeHeight end

    updateVelocity(camera, timeDelta * 60, jump, w, s, a, d)
    collideHorizontal(sectorArr, vertexArr, camera, eyes)

    -- Get origin
    local xOrigin = vertexArr[sectorArr[camera.sector + 1].vertex[1].idx + 1].x
    local yOrigin = vertexArr[sectorArr[camera.sector + 1].vertex[1].idx + 1].y

    collideVertical(
        {
            floor = geo.planeZ(sectorArr[camera.sector + 1].floor, xOrigin, yOrigin, camera.where.x, camera.where.y),
            ceil  = geo.planeZ(sectorArr[camera.sector + 1].ceil,  xOrigin, yOrigin, camera.where.x, camera.where.y)
        },
        camera, timeDelta * 60, eyes
    )
end

return mov