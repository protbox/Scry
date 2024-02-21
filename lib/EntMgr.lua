local Class = require "lib.Class"

local EntMgr = Class:extends()

local sort_by_layer = function(a, b)
    return a.layer < b.layer
end

function EntMgr:sort()
    table.sort(self.ents, sort_by_layer)
end

function EntMgr:new(...)
    self.ents = {}
    self.vis_ents = {}
end

function EntMgr:reset()
    for i = #self.ents, 1, -1 do
        if not self.ents[i].is_player then
            self.ents[i].remove = true
            self.ents[i]:destroy()
        end
    end
    self.ents = {}
end

function EntMgr:add(ent)
    table.insert(self.ents, ent)
    table.sort(self.ents, function(a, b) return a.layer > b.layer end)
    if self.world then self.world:add(ent, ent.x, ent.y, ent.w, ent.h) end
end

function EntMgr:update(dt)
  for i = #self.ents, 1, -1 do
    if self.ents[i] ~= nil then
      if self.ents[i].remove then
        self.ents[i]:destroy()
        table.remove(self.ents, i)
      else
        self.ents[i]:update(dt)
      end
    end
  end
end

function EntMgr:draw()
  for i = #self.ents, 1, -1 do
    self.ents[i]:draw()
  end
end

return EntMgr
