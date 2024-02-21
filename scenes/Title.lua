local Scene = require "lib.Scene"

local Title = Scene:extends()

function Title:new()
end

function Title:update(dt)
end

function Title:draw()
    love.graphics.setColor(1, 1, 1, 1)
end

return Title