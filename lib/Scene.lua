local Class = require "lib.Class"
local EntMgr = require "lib.EntMgr"

local Scene = Class:extends()

function Scene:new()
	--self.ent_mgr = EntMgr()
end

function Scene:on_enter() end

function Scene:update(dt)
    --if self.ent_mgr ~= nil then self.ent_mgr:update(dt) end
end

function Scene:draw()
    love.graphics.setColor(1, 1, 1, 1)
    --if self.ent_mgr ~= nil then self.ent_mgr:draw() end
end

function Scene:mousepressed(x, y, button, istouch, presses)
end

function Scene:keypressed(key, sc)
end

return Scene
