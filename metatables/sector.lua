-- Sectors geometry data and map graph linking
--
-- Methods are indexed from zero
local Sector = {
    -- List of xy coordinates of sector verteces
    nodes = {},
    -- List of precalculated trygonometric values for walls
    walls = {},
    -- List of neighboring sectors per wall
    links = {},

    -- Ceiling height
    topPlane    = 0,
    -- Floor height
    bottomPlane = 0
}

-- Create new sector
function Sector:new (nodes, links, ceil, floor)
    local sector = {
        nodes = nodes or {},
        links = links or {},

        topPlane    = ceil or 0,
        bottomPlane = floor or 0
    }

    setmetatable(sector, self)
    self.__index = self

    for idx = 0, #self.nodes-1 do
        table.insert(self.walls, {})
        self:calculateWall(idx)
    end

    return sector
end

-- Return indicated node
function Sector:nodeAt (index)
    index = (index % #self.nodes) + 1
    return self.nodes[index]
end

-- Set new value for given node
function Sector:nodeSet (index, x, y)
    index = (index % #self.nodes) + 1

    self.nodes[index].x = x
    self.nodes[index].y = y

    self:calculateWall(index)
    self:calculateWall(index - 1)
end

-- Return ceiling height
function Sector:ceil ()
    return self.topPlane
end

function Sector:ceilSet (height)
    self.topPlane = height
end

-- Return floor height
function Sector:floor ()
    return self.bottomPlane
end

function Sector:floorSet (height)
    self.bottomPlane = height
end

-- Calculate trygonometric values of indicated wall
function Sector:calculateWall (index)
    local xOff = self:nodeAt(index).x - self:nodeAt(index + 1).x
    local yOff = self:nodeAt(index).y - self.nodeAt(index + 1).y

    local wallLen = math.sqrt(xOff^2 + yOff^2)
    self.walls[index].dx =  yOff / wallLen
    self.walls[index].dy = -xOff / wallLen
end

return Sector