local geo = {}

-- Clamps the given number value according to passed bounds
geo.clamp = function (number, lower, upper)
    return math.min(math.max(number, lower), upper)
end

-- Returns the Vector Cross Product of given vectors A and B
geo.vxp = function (Ax, Ay, Bx, By)
    return (Ax * By) - (Ay * Bx)
end

-- First step of calculating the intersection point beetwen vectors AB and CD
-- Return u-values that can be used to determine whether the intersection happens beetwen vector bounds
-- u-values in [0, 1] if on vector
-- u-values can be used to calculate the intersection point
geo.intersect = function (Ax, Ay, Bx, By, Cx, Cy, Dx, Dy)
    local d = geo.vxp(Ax - Bx, Ay - By, Cx - Dx, Cy - Dy)
    local uValue = geo.vxp(Cx - Dx, Cy - Dy, Bx - Cx, By - Cy) / d

    return {
        x = Bx + (uValue * (Ax - Bx)),
        y = By + (uValue * (Ay - By))
    }
end

-- Checks if camera is inside a given confines
geo.checkInside = function (sector, player)
    local inside = false

    local px = player.where.x
    local py = player.where.y

    for idx = 1, #sector.nodes do
        -- Hold both points
        local x1 = sector:nodeAt(idx + 0).x
        local y1 = sector:nodeAt(idx + 0).y
        local x2 = sector:nodeAt(idx + 1).x
        local y2 = sector:nodeAt(idx + 1).y

        -- Correct order
        if y1 > y2 then
            x1, x2 = x2, x1
            y1, y2 = y2, y1
        end

        if py <= y1 and py < y2 then goto continue end -- below
        if py >= y1 and py > y2 then goto continue end -- above
        if px >= x1 and px > x2 then goto continue end -- right
        if px <= x1 and px < x2 then -- left
            inside = not inside
            goto continue
        end
        if (x2 - x1) * (py - y1) - (y2 - y1) * (px - x1) > 0 then
            inside = not inside
        end

        ::continue::
    end

    return inside
end

return geo