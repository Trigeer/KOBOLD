io.stdout:setvbuf("no")

-- Imports
require("constants")
local lod = require("lib.loadingFunctions")
local gpx = require("lib.graphicFunctions")
local mov = require("lib.movementFunctions")

-- Active data
local sectorArr = {}
local textures  = {}
local camera = {}

function love.load()
    local result = lod.loadMapGeometry("maps/map0_geometry.lua")
    textures = lod.loadMapTexturing("maps/map0_texturing.lua")

    sectorArr = result[1]
    camera    = result[2]

    love.mouse.setRelativeMode(true)
    love.window.setMode(ScreenWidth * Scaling, ScreenHeight * Scaling)
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
    gpx.drawScreen(sectorArr, textures, camera)
end

-- Look around
function love.mousemoved(x, y, dx, dy, istouch)
    mov.moveCamera(camera, dx, dy)
end

-- Crouching (and mouse release)
function love.keypressed(key, scancode, isrepeat)
    if key == "lshift" then camera.grounded = false end
    if key == "escape" then love.mouse.setRelativeMode(false) end
end

function love.keyreleased(key, scancode, isrepeat)
    if key == "lshift" then camera.grounded = false end
end