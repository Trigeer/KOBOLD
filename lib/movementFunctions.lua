require("constants")
local geo  = require("lib.geometricFunctions")
local util = require("lib.utilities")

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

local function collideHorizontal(sectorArr, camera, eyes)
    local checkAgainst = {camera.sector}
    
    camera.where.x = camera.where.x + camera.velocity.x
    camera.where.y = camera.where.y + camera.velocity.y

    -- Calculate camera bounds
    local cameraTop = camera.where.z + HeadMargin
    local cameraMid = camera.where.z + KneeHeight - eyes
    
    for _, sec in ipairs(checkAgainst) do
        local sector = sectorArr[sec]

        for idx = 1, #sector.nodes do
            local x1 = sector:nodeAt(idx + 0).x
            local y1 = sector:nodeAt(idx + 0).y
            local x2 = sector:nodeAt(idx + 1).x
            local y2 = sector:nodeAt(idx + 1).y

            local xDelta = x2 - x1
            local yDelta = y2 - y1

            -- Player and wall difference
            local pdx = camera.where.x - x1
            local pdy = camera.where.y - y1
            local dot = (xDelta * pdx + yDelta * pdy) / (xDelta^2 + yDelta^2)

            -- Skip on too far
            local ends = WallOffset / math.sqrt(xDelta^2 + yDelta^2)
            if 0 - ends > dot or dot > 1 + ends then goto continue end

            local d = {
                x = dot * xDelta + x1,
                y = dot * yDelta + y1
            }
            local dist = math.sqrt((d.x - camera.where.x)^2 + (d.y - camera.where.y)^2)
            local crossP = geo.vxp(xDelta, yDelta, pdx, pdy)

            if dist < WallOffset or crossP <= 0 then
                local neighbors = sector.links[idx]

                if next(neighbors) ~= nil then
                    -- Calculate local sector heights
                    local holeLow = sector:floor(d)
                    local holeTop = sector:ceil(d)

                    for _, neighbor in ipairs(neighbors) do

                        local boundLow = math.max(
                            holeLow,
                            sectorArr[neighbor]:floor(d)
                        )
                        local boundTop = math.min(
                            holeTop,
                            sectorArr[neighbor]:ceil(d)
                        )

                        if boundTop - boundLow >= eyes + HeadMargin and boundLow <= cameraMid and boundTop >= cameraTop then
                            if not util.table_contains(checkAgainst, neighbor) then
                                table.insert(checkAgainst, neighbor)
                            end
                            goto continue
                        end
                    end
                end

                camera.where.x = d.x + sector.walls[idx].dx * WallOffset
                camera.where.y = d.y + sector.walls[idx].dy * WallOffset
            end

        ::continue::
        end
    end

    for _, sec in ipairs(checkAgainst) do
        if geo.checkInside(sectorArr[sec], camera) then
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
mov.calculateMove = function (sectorArr, camera, timeDelta, jump, crouch, w, s, a, d)
    local eyes = 0
    if crouch then eyes = DuckHeight else eyes = EyeHeight end

    updateVelocity(camera, timeDelta * 60, jump, w, s, a, d)
    collideHorizontal(sectorArr, camera, eyes)

    collideVertical(
        {
            floor = sectorArr[camera.sector]:floor(camera.where),
            ceil  = sectorArr[camera.sector]:ceil(camera.where)
        },
        camera, timeDelta * 60, eyes
    )
end

return mov