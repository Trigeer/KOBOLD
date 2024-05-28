io.stdout:setvbuf("no")

-- Imports
require("constants")
local lod = require("lib.loadingFunctions")
local gpx = require("lib.graphicFunctions")
local mov = require("lib.movementFunctions")
local dyn = require("lib.dynamicFunctions")

-- Active data
local sectorArr = {}
local eventsArr = {}
local textures  = {}
local triggers  = {}
local camera = {}

local dummy = {}

function love.load()
    local result = lod.loadMapGeometry("maps/map0_geometry.lua")
    textures  = lod.loadMapTexturing("maps/map0_texturing.lua")
    eventsArr = lod.loadMapDynamics("maps/map0_dynamics.lua")
    triggers  = lod.loadTriggers("maps/map0_dynamics.lua")

    sectorArr = result[1]
    camera    = result[2]

    dummy = {
        where = {
            x = 10,
            y = 2.5,
            z = sectorArr[22]:floor({x = 10, y = 2.5}) + EyeHeight + 1e-5
        },
        angle  = 0,
        sector = 22,
        pitch  = 0,
    
        -- Control values
        velocity = {x = 0, y = 0, z = 0},
        grounded = false
    }

    love.mouse.setRelativeMode(true)
    love.window.setMode(ScreenWidth * Scaling, ScreenHeight * Scaling)
end

function love.update(dt)
    dyn.executeEvents(sectorArr, eventsArr, dt)
    local visited = mov.calculateMove(
        sectorArr, camera, dt,
        love.keyboard.isDown("space"),
        love.keyboard.isDown("lshift"),
        love.keyboard.isDown("w"),
        love.keyboard.isDown("s"),
        love.keyboard.isDown("a"),
        love.keyboard.isDown("d")
    )

    mov.calculateMove(
        sectorArr, dummy, dt,
        love.keyboard.isDown("o"),
        love.keyboard.isDown("p"),
        love.keyboard.isDown("up"),
        love.keyboard.isDown("down"),
        love.keyboard.isDown("left"),
        love.keyboard.isDown("right")
    )
    dyn.checkTriggers(triggers, visited, camera, love.keyboard.isDown("e"))
end

function love.draw()
    gpx.drawScreen(sectorArr, {dummy}, textures, camera)
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