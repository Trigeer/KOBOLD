io.stdout:setvbuf("no")

require("constants")
local lod = require("lib.loadingFunctions")
local gpx = require("lib.graphicFunctions")
local mov = require("lib.movementFunctions")

local vertexArr = {}
local sectorArr = {}
local camera = {}

function love.load()
    local result = lod.loadMap("maps/map0.lua")

    vertexArr = result[1]
    sectorArr = result[2]
    camera = result[3]
end

function love.update(dt)
    mov.calculateMove(
        sectorArr, camera, dt,
        love.keyboard.isDown("space"),
        love.keyboard.isDown("lshift"),
        love.keyboard.isDown("w"),
        love.keyboard.isDown("s"),
        love.keyboard.isDown("a"),
        love.keyboard.isDown("d")
    )
end

function love.draw()
    gpx.drawScreen(vertexArr, sectorArr, camera)
end

-- Look around
function love.mousemoved(x, y, dx, dy, istouch)
    mov.moveCamera(camera, dx, dy)
end

-- Crouching
function love.keypressed(key, scancode, isrepeat)
    if key == "lshift" then camera.grounded = false end
end

function love.keyreleased(key, scancode, isrepeat)
    if key == "lshift" then camera.grounded = false end
end