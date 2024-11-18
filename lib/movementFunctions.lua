require("constants")
local geo  = require("lib.helpers.geometricFunctions")
local util = require("lib.helpers.utilities")
local dyn  = require("lib.dynamicFunctions")

local mov = {}

local function updateVelocity(camera, timeDelta, jump, w, s, a, d)
    -- Jumping
    if jump and camera.grounded then
        camera.velocity.z = 0.3
        camera.grounded = false
    end

    local inverse = 0.70710676908493 -- 1/sqrt(2)

    -- Apply key presses
    local camSin = math.sin(camera.angle)
    local camCos = math.cos(camera.angle)
    local mod = {ws = 0, ad = 0}
    if w and not s then mod.ws = Speed elseif not w and s then mod.ws = -Speed end
    if a and not d then mod.ad = Speed elseif not a and d then mod.ad = -Speed end

    if mod.ws ~= 0 and mod.ad ~= 0 then
        mod.ws = mod.ws * inverse
        mod.ad = mod.ad * inverse
    end

    local moveVector = {
        x = mod.ws * camCos + mod.ad * camSin,
        y = mod.ws * camSin - mod.ad * camCos
    }

    local decay = DecayTop
    if w or s or a or d then decay = DecayLow end

    local d = (1 - decay^timeDelta) / (1 - decay);

    -- New velocity
    camera.velocity.x = camera.velocity.x * decay^timeDelta + moveVector.x * d;
    camera.velocity.y = camera.velocity.y * decay^timeDelta + moveVector.y * d;
end

-- Bounds indicate floor and ceiling height
local function collideVertical(sectorArr, eventsArr, controllers, triggers, flags, bounds, camera, timeDelta, eyes)
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

local function collideHorizontal(sectorArr, eventsArr, controllers, triggers, flags, camera, eyes)
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
            -- local ends = 1e-5 --WallOffset / math.sqrt(xDelta^2 + yDelta^2)
            if 0 > dot or dot > 1 then goto continue end

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

                    for nidx, neighbor in ipairs(neighbors) do

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
                                dyn.checkTriggers(
                                    sectorArr, eventsArr, controllers, triggers, flags,
                                    sector.triggers.onPortal[nidx],
                                    sec, "lack thereof"
                                )
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
            if camera.sector ~= sec then
                dyn.checkTriggers(
                    sectorArr, eventsArr, controllers, triggers, flags,
                    sectorArr[sec].triggers.onEnter,
                    sec, "lack thereof"
                )
                dyn.checkTriggers(
                    sectorArr, eventsArr, controllers, triggers, flags,
                    sectorArr[camera.sector].triggers.onLeave,
                    camera.sector, "lack thereof"
                )
                camera.sector = sec
            end
            break
        end
    end

    return checkAgainst
end

mov.moveCamera = function (camera, xDelta, yDelta)
    camera.angle = camera.angle + xDelta * SensitivityX
    camera.pitch = geo.clamp(camera.pitch + yDelta * SensitivityY, -5, 5)
end

-- Locked to assumed 60 FPS
mov.calculateMove = function (sectorArr, eventsArr, controllers, triggers, flags, camera, timeDelta, jump, crouch, w, s, a, d)
    local eyes = 0
    if crouch then eyes = DuckHeight else eyes = EyeHeight end

    updateVelocity(camera, math.floor(timeDelta * 60), jump, w, s, a, d)

    local visited = collideHorizontal(sectorArr, eventsArr, controllers, triggers, flags, camera, eyes)
    collideVertical(
        sectorArr, eventsArr, controllers, triggers, flags,
        {
            floor = sectorArr[camera.sector]:floor(camera.where),
            ceil  = sectorArr[camera.sector]:ceil(camera.where)
        },
        camera, math.floor(timeDelta * 60), eyes
    )

    dyn.checkTriggers(
        sectorArr, eventsArr, controllers, triggers, flags,
        sectorArr[camera.sector].triggers.onPresent,
        camera.sector, "lack thereof"
    )

    return visited
end

return mov