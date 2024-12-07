function sine_wave(flags, delta)
    local peak = math.sin(math.pi * ((2 * delta - 5) / 10)) + 1
    return {{
        type = "sector",
        subtype = "bottomPlane",
        locate = {
            index  = 1,
            detail = 0
        },
        action = "UPDATE",
        newValue = peak
    }}
end

function wall(flags, delta)
    local peak = math.sin(math.pi * ((2 * delta - 5) / 10)) + 1
    return {
        {
            type = "sector",
            subtype = "nodes",
            locate = {
                index = 0,
                detail = 1,
                coord = "x"
            },
            newValue = -peak
        },
        {
            type = "sector",
            subtype = "nodes",
            locate = {
                index = 0,
                detail = 2,
                coord = "x"
            },
            newValue = -peak
        }
    }
end