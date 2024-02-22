local SceneMgr = {
  current = nil,
  scenes  = {}
}

function SceneMgr:add(scenes)
  assert(scenes ~= nil and type(scenes) == "table", "SceneMgr:add expects a table")
  for k,v in pairs(scenes) do
    self.scenes[k] = v
    v.name = k
  end
end

function SceneMgr:get_scene(name)
    assert(self.scenes[name], "No such scene exists (" .. name .. ")")
    return self.scenes[name]
end

function SceneMgr:switch(scene, ...)
  assert(self.scenes[scene], "Cannot switch to scene '" .. scene .. "' because it doesn't exist")
    if self.current and self.current.on_exit then
        self.current:on_exit()
    end
    
    self.current = self.scenes[scene]
    self.current:on_enter(...)
end

function SceneMgr:update(dt) self.current:update(dt)  end
function SceneMgr:draw() self.current:draw() end
function SceneMgr:mousepressed(x, y, button, istouch, presses)
  self.current:mousepressed(x, y, button, istouch, presses)
end
function SceneMgr:mousereleased(x, y, button)
  self.current:mousereleased(x, y, button)
end
function SceneMgr:mousemoved(x, y, dx, dy, istouch)
  if self.current.mousemoved then self.current:mousemoved(x, y, dx, dy, istouch) end
end

function SceneMgr:keypressed(key, sc) self.current:keypressed(key, sc) end

return SceneMgr
