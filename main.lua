io.stdout:setvbuf("no")

-- Imports
require("constants")
local lod = require("lib.loadingFunctions")
local gpx = require("lib.graphicFunctions")
local mov = require("lib.movementFunctions")
local dyn = require("lib.dynamicFunctions")
local net = require("lib.networkingFunctions")

-- Active data
local sectorArr   = {}
local eventsArr   = {}
local textures    = {}
local triggers    = {}
local controllers = {}
local camera = {}

local flags = {}

-- This should be renamed
local dummy = {}
local mode
local eventful = false

function love.load()
    print("Input map package")
    io.write("package> ")
    local pack = io.read("*l")

    -- print("Select mode:")
    -- print("  1 for Online")
    -- print("  2 for Offline")
    -- io.write("console> ")
    -- local modeNum = io.read("*n")
    local modeNum = 2
    local ip = ''
    local port = 0
    local user = 'NULL'

    if modeNum == 1 then
        mode = true

        io.write("host IP> ")
        ip = io.read("*l")
        io.write("host port> ")
        port = io.read("*n")
        io.write("username> ")
        user = io.read("*l")
    elseif modeNum == 2 then
        mode = false
    else
        error("Illegal mode...")
    end

    local result = lod.loadMapGeometry(pack .. "_geometry.json")
    textures  = lod.loadMapTexturing(pack .. "_texturing.lua")

    sectorArr = result[1]
    camera    = result[2]

    if eventful then
        controllers, triggers, eventsArr, flags = lod.loadMapDynamics("maps/testing_ground/header.json", sectorArr)
    end

    if mode then
        net.connect(ip, port, user)
        net.send(0, {ws = 0, ad = 0}, false, camera.angle)
    end

    -- dummy = {{
    --     where = {
    --         x = 10,
    --         y = 2.5,
    --         z = sectorArr[22]:floor({x = 10, y = 2.5}) + EyeHeight + 1e-5
    --     },
    --     angle  = 0.1,
    --     sector = 22,
    --     pitch  = 0,
    
    --     -- Control values
    --     velocity = {x = 0, y = 0, z = 0},
    --     grounded = false
    -- }}

    love.mouse.setRelativeMode(true)
    love.window.setMode(ScreenWidth * Scaling, ScreenHeight * Scaling)
end

function love.update(dt)
    if eventful then
        dyn.executeEvents(sectorArr, eventsArr, controllers, triggers, flags, dt)
        dyn.control(sectorArr, eventsArr, controllers, triggers, flags)
    end

    dummy = {}

    if mode then
        local w = love.keyboard.isDown("w")
        local s = love.keyboard.isDown("s")
        local a = love.keyboard.isDown("a")
        local d = love.keyboard.isDown("d")

        local mod = {ws = 0, ad = 0}
        if w and not s then mod.ws = 1 elseif not w and s then mod.ws = -1 end
        if a and not d then mod.ad = 1 elseif not a and d then mod.ad = -1 end

        local response, uuid = net.receive()
        net.send(dt, mod, love.keyboard.isDown("space"), camera.angle)

        if response then
            for index, value in ipairs(response) do
                if value.enabled then
                    table.insert(dummy, {
                        where = {
                            x = value.x,
                            y = value.y,
                            z = value.z
                        },
                        angle = 0,
                        sector = value.sector + 1
                    })

                    if index == uuid then
                        camera.where.x = value.x
                        camera.where.y = value.y
                        camera.where.z = value.z
                        camera.sector  = value.sector + 1
                    end
                end
            end
        end
    else
        local visited = mov.calculateMove(
            sectorArr, eventsArr, controllers, triggers, flags,
            camera, dt,
            love.keyboard.isDown("space"),
            love.keyboard.isDown("lshift"),
            love.keyboard.isDown("w"),
            love.keyboard.isDown("s"),
            love.keyboard.isDown("a"),
            love.keyboard.isDown("d")
        )
    end
end

function love.draw()
    gpx.drawScreen(sectorArr, dummy, textures, camera)
end

-- Look around
function love.mousemoved(x, y, dx, dy, istouch)
    mov.moveCamera(camera, dx, dy)
end

-- Crouching (and mouse release)
function love.keypressed(key, scancode, isrepeat)
    -- if key == "lshift" then camera.grounded = false end
    if key == "escape" then love.mouse.setRelativeMode(false) end
end

function love.keyreleased(key, scancode, isrepeat)
    -- if key == "lshift" then camera.grounded = false end
end

function love.quit()
    if mode then net.close() end
    return false
end