function sine_wave(delta)
    local peak = 5 * math.sin(math.pi * ((2 * delta - 5) / 10)) + 5
    return {{
        type = "sector",
        subtype = "bottomPlane",
        locate = {
            index  = 4,
            detail = 0
        },
        action = "UPDATE",
        newValue = peak
    }}
end