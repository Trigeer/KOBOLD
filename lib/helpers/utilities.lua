local utils = {}

function utils.shallow(orig)
    local orig_type = type(orig)
    local copy
    if orig_type == 'table' then
        copy = {}
        for orig_key, orig_value in pairs(orig) do
            copy[orig_key] = orig_value
        end
    else -- number, string, boolean, etc
        copy = orig
    end
    return copy
end

function utils.table_contains(tbl, x)
    for _, v in pairs(tbl) do
        if v == x then 
            return true 
        end
    end
    return false
end

-- Scaler -> {result, bop, fd, ca, cache}
utils.scalerInit = function (a, b, c, d, f)
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
utils.scalerNext = function (scaler)
    scaler.cache = scaler.cache + scaler.fd
    while scaler.cache >= scaler.ca do
        scaler.result = scaler.result + scaler.bop
        scaler.cache = scaler.cache - scaler.ca
    end
    return scaler.result
end

return utils