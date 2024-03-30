-- Imports
local Sector = require("metatables.sector")

local SlantedSector = Sector:new()

function SlantedSector:ceil (point)
    local xDelta = (point.x - self:nodeAt(0).x) * math.tan(self.topPlane.dx)
    local yDelta = (point.y - self:nodeAt(0).y) * math.tan(self.topPlane.dy)

    return self.topPlane.height + xDelta + yDelta
end

function SlantedSector:floor (point)
    local xDelta = (point.x - self:nodeAt(0).x) * math.tan(self.bottomPlane.dx)
    local yDelta = (point.y - self:nodeAt(0).y) * math.tan(self.bottomPlane.dy)

    return self.bottomPlane.height + xDelta + yDelta
end

function SlantedSector:ceilSet (height, dx, dy)
    self.topPlane.height = height
    self.topPlane.dx = dx
    self.topPlane.dy = dy
end

function SlantedSector:floorSet (height, dx, dy)
    self.bottomPlane.height = height
    self.bottomPlane.dx = dx
    self.bottomPlane.dy = dy
end

return SlantedSector