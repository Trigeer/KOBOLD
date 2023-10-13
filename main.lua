io.stdout:setvbuf("no")

require("constants")
local lod = require("lib.loadingFunctions")
local gpx = require("lib.graphicFunctions")
local mov = require("lib.movementFunctions")

local vertexArr = nil
local sectorArr = nil
local camera = nil

function love.load()
    lod.loadMap("maps/map0.lua")
end

function love.update(dt)

end

function love.draw()
    gpx.drawScreen(vertexArr, sectorArr, camera)
end