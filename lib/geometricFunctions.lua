local geo = {}

-- Clamps the given number value according to passed bounds
geo.clamp = function (number, lower, upper)
    return math.min(math.max(number, lower), upper)
end

-- Returns the Vector Cross Product of given vectors A and B
geo.vxp = function (Ax, Ay, Bx, By)
    return (Ax * By) - (Ay * Bx)
end

-- Returns on which side of the given line AB the point P lies
geo.pointSide = function (Px, Py, Ax, Ay, Bx, By)
    return geo.vxp(Bx - Ax, By - Ay, Px - Ax, Py - Ay)
end

-- Casts point P to line AB
geo.cast = function (Px, Py, Ax, Ay, Bx, By)
    local xDelta = Ax - Bx
    local yDelta = Ay - By
    local dot = ( ((Px-Bx)*xDelta) + ((Py-By)*yDelta) ) / (xDelta^2 + yDelta^2)
    return {x = Bx + (dot * xDelta), y = By + (dot * yDelta)}
end

-- First step of calculating the intersection point beetwen vectors AB and CD
-- Return u-values that can be used to determine whether the intersection happens beetwen vector bounds
-- u-values in [0, 1] if on vector
-- u-values can be used to calculate the intersection point
geo.intercheck = function (Ax, Ay, Bx, By, Cx, Cy, Dx, Dy)
    local d = geo.vxp(Ax - Bx, Ay - By, Cx - Dx, Cy - Dy)
    return {
        uAB = geo.vxp(Cx - Dx, Cy - Dy, Bx - Cx, By - Cy) / d,
        uCD = geo.vxp(Bx - Cx, By - Cy, Ax - Bx, Ay - By) / d
    }
end

-- IMPORTANT: use relevant u-value to vector coordinates
geo.intersect = function (uValue, Ax, Ay, Bx, By)
    return {
        x = Bx + (uValue * (Ax - Bx)),
        y = By + (uValue * (Ay - By))
    }
end

-- Scaler -> {result, bop, fd, ca, cache}
geo.scalerInit = function (a, b, c, d, f)
    local bop = 1
    if ((f < d) or (c < a)) and not ((f < d) and (c < a)) then
        bop = -1
    end
    return {
        result = d + (b - 1 - a) * (f - d) / (c - a),
        bop = bop,
        fd = math.abs(f - d),
        ca = math.abs(c - a),
        cache = ((b - 1 - a) * math.abs(f - d)) % math.abs(c - a)
    }
end
geo.scalerNext = function (scaler)
    scaler.cache = scaler.cache + scaler.fd
    while scaler.cache >= scaler.ca do
        scaler.result = scaler.result + scaler.bop
        scaler.cache = scaler.cache - scaler.ca
    end
    return scaler.result
end

return geo