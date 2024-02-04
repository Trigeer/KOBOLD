local map0 = {
    events = {
        { -- Vertex group
            type = 0,
            group = {},
            -- affected = {{val = 0, points = {}}},
            loopTime = 0,
            code = function (self, cache)
                local results = {{x = 0, y = 0}}
        
                -- Magick here
        
                return results
            end
        },
        { -- Sector group
            type = 1,
            group = {},
            loopTime = 0,
            code = function (self, cache)
                local results = {{floor = {0, 0, 0}, ceil = {0, 0, 0}}}
        
                -- Magick here
        
                return results
            end
        }
    }
}

return map0