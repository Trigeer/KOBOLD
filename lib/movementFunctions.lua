require("constants")
local geo = require("lib.geometricFunctions")

local mov = {}

local function updateVelocity(camera, timeDelta, jump, w, s, a, d)
    -- Jumping
    if jump and camera.grounded then
        camera.velocity.z = 0.7
        camera.grounded = false
    end

    -- Apply key presses
    local camSin = math.sin(camera.angle) * 0.2
    local camCos = math.cos(camera.angle) * 0.2
    local mod = {ws = 0, ad = 0}
    if w and not s then mod.ws = 1 elseif not w and s then mod.ws = -1 end
    if a and not d then mod.ad = 1 elseif not a and d then mod.ad = -1 end
    local moveVector = {
        x = mod.ws * camCos + mod.ad * camSin,
        y = mod.ws * camSin - mod.ad * camCos
    }

    local acceleration = 0
    if w or s or a or d then acceleration = 0.25 else acceleration = 0.2 end

    -- New velocity
    camera.velocity.x = (camera.velocity.x * (1 - acceleration) + moveVector.x * acceleration) * timeDelta
    camera.velocity.y = (camera.velocity.y * (1 - acceleration) + moveVector.y * acceleration) * timeDelta
end

-- Bounds indicate floor and ceiling height
local function collideVertical(bounds, camera, timeDelta, eyes)
    if not camera.grounded then
        
        -- Gravity
        camera.velocity.z = camera.velocity.z - 0.05 * timeDelta
        local next = camera.where.z + camera.velocity.z

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
end

local function collideHorizontal(sectorArr, camera, eyes)
    local xCam = camera.where.x
    local yCam = camera.where.y
    local sector   = sectorArr[camera.sector + 1]
    local collider = sector.collisions

    local poi = {x = xCam + camera.velocity.x, y = yCam + camera.velocity.y, sd = math.huge}

    for idx = 1, sector.npoints do
        local x1 = collider[idx + 0].x
        local y1 = collider[idx + 0].y
        local x2 = collider[idx + 1].x
        local y2 = collider[idx + 1].y

        -- Lack of collision
        if geo.pointSide(xCam + camera.velocity.x, yCam + camera.velocity.y, x1, y1, x2, y2) > 0 then goto continue end

        local u = geo.intercheck(xCam, yCam, xCam + camera.velocity.x, yCam + camera.velocity.y, x1, y1, x2, y2)
        if u.uAB > 0 and u.uAB < 1 and u.uCD >= 0 and u.uCD <= 1 and next(sector.neighbor[idx]) ~= nil then
            local target = 0
            for t, n in pairs(sector.neighbor[idx]) do
                if sectorArr[n + 1].ceil >= camera.where.z + HeadMargin then
                    target = t
                else break end
            end

            if target > 0 then
                local holeLow = sectorArr[sector.neighbor[idx][target] + 1].floor
                local holeTop = sectorArr[sector.neighbor[idx][target] + 1].ceil

                if holeLow <= camera.where.z - eyes + KneeHeight and holeTop - holeLow >= eyes + HeadMargin then
                    camera.sector   = sector.neighbor[idx][target]
                    camera.grounded = false
                    -- TODO: Reduce recursion
                    collideHorizontal(sectorArr, camera, eyes)
                    return
                end
            end
        end

        local c = geo.cast(xCam + camera.velocity.x, yCam + camera.velocity.y, x1, y1, x2, y2)

        c.x  = geo.clamp(c.x, math.min(x1, x2), math.max(x1, x2))
        c.y  = geo.clamp(c.y, math.min(y1, y2), math.max(y1, y2))
        c.sd = (c.x - xCam + camera.velocity.x)^2 + (c.y - yCam + camera.velocity.y)^2

        if c.sd < poi.sd then poi = c end

        ::continue::
    end

    camera.where.x = poi.x
    camera.where.y = poi.y

end

mov.moveCamera = function (camera, xDelta, yDelta)
    camera.angle = camera.angle + xDelta * 0.03
    camera.pitch = geo.clamp(camera.pitch + yDelta * 0.05, -5, 5)
end

mov.calculateMove = function (sectorArr, camera, timeDelta, jump, crouch, w, s, a, d)
    local eyes = 0
    if crouch then eyes = DuckHeight else eyes = EyeHeight end

    updateVelocity(camera, timeDelta * 60, jump, w, s, a, d)
    collideHorizontal(sectorArr, camera, eyes)
    collideVertical(
        {
            floor = sectorArr[camera.sector + 1].floor,
            ceil  = sectorArr[camera.sector + 1].ceil
        },
        camera, timeDelta * 60, eyes
    )
end

return mov