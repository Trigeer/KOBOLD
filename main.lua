io.stdout:setvbuf("no")

-- Imports
require("constants")
local lod = require("lib.loadingFunctions")
local gpx = require("lib.graphicFunctions")
local mov = require("lib.movementFunctions")
local dyn = require("lib.dynamicFunctions")

-- Active data
local vertexArr = {}
local sectorArr = {}
local textures  = {}
local triggers  = {}
local camera = {}

function love.load()
    local result = lod.loadMapGeometry("maps/map0_geometry.lua")
    textures = lod.loadMapTexturing("maps/map0_texturing.lua")
    triggers = lod.loadTriggers("maps/map0_triggers.lua")

    vertexArr = result[1]
    sectorArr = result[2]
    camera = result[3]

    love.mouse.setRelativeMode(true)
    love.window.setMode(ScreenWidth * Scaling, ScreenHeight * Scaling)
end

function love.update(dt)
    local visited = mov.calculateMove(
        sectorArr, vertexArr, camera, dt,
        love.keyboard.isDown("space"),
        love.keyboard.isDown("lshift"),
        love.keyboard.isDown("w"),
        love.keyboard.isDown("s"),
        love.keyboard.isDown("a"),
        love.keyboard.isDown("d")
    )
    dyn.checkTriggers(triggers, visited, camera, love.keyboard.isDown("e"))
end

function love.draw()
    gpx.drawScreen(vertexArr, sectorArr, textures, camera)
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