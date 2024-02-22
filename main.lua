-- set the filter to nearest so there's no weird bluriness
love.graphics.setDefaultFilter("nearest", "nearest")

-- hopefully the only global we'll ever need
SceneMgr = require "lib.SceneMgr"

function love.load()
    SceneMgr:add({
        Game = require("scenes.Game")(),
        Title = require("scenes.Title")()
    })
    SceneMgr:switch("Title")
end

function love.update(dt)
    SceneMgr:update(dt)
end

function love.draw()
    SceneMgr:draw()
end

function love.keypressed(key, sc)
    SceneMgr:keypressed(key, sc)
end

function love.mousepressed(x, y, button, istouch, presses)
    SceneMgr:mousepressed(x, y, button, istouch, presses)
end

function love.mousemoved(x, y, dx, dy, istouch)
    SceneMgr:mousemoved(x, y, dx, dy, istouch)
end