local Class = require "lib.Class"

local Ent = Class:extends()

function Ent:new(...)
    local args = {...}
    self.x = args[1]
    self.y = args[2]
    self.h = args[3] or 16
    self.w = args[4] or 16
    self.opt = args[5] or {}

    self.layer = 1
    self.move_ctr = 1
    self.yoffset = 0
    self.easing = "elasticout"
    self.state = "idle"
end

function Ent:set_state(state)
    if self.state ~= state then self.anims[self.state]:gotoFrame(1) end
    self.state = state
end

local function clone(obj, seen)
    -- Handle non-tables and previously-seen tables.
    if type(obj) ~= 'table' then return obj end
    if seen and seen[obj] then return seen[obj] end

    -- New table; mark it as seen an copy recursively.
    local s = seen or {}
    local res = {}
    s[obj] = res
    for k, v in next, obj do res[clone(k, s)] = clone(v, s) end
    return setmetatable(res, getmetatable(obj))
end

function Ent:post()
    self.orig = clone(self)
end

function Ent:world() return SceneMgr:get_scene('Game').world end

function Ent:update(dt)
end

function Ent:draw()
    love.graphics.setColor(1, 1, 1, 1)
    -- spr(self.spr and self.spr or self.n, self.x, self.y)
end

function Ent:get_distance(e2)
    return math.sqrt((e2.x - self.x) ^ 2 + (e2.y - self.y) ^ 2)
end

function Ent:draw_rect()
    local rx, ry, rw, rh = SceneMgr:get_scene('Game').world:getRect(self)
    love.graphics.rectangle("line", rx, ry, rw, rh)
end

function Ent:update_hitbox(w, h)
    self:world():update(self, self.x, self.y, w, h)
end

function Ent:destroy()
	--[[local world = self:world()

	if self.respawn then
		self.orig:post()
		SceneMgr:get_scene('Game').respawner:add(self.orig)
	end

    world:remove(self)]]
    self.remove = true
end

return Ent