

local Scoreboard = {
    board = {},
    template = {}
}

function Scoreboard:new (template)
    local scoreboard = {
        template = template or {}
    }

    setmetatable(scoreboard, self)
    self.__index = self

    return scoreboard
end

function Scoreboard:newEntry (uuid)
    local entry = {uuid = uuid}
    setmetatable(entry, self.template)
    self.template.__index = self.template
    table.insert(self.board, entry)

    return #self.board
end