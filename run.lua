local rate = 1/60 -- or 1/whatever rate you want
local accumulator = 0
function love.run()
  if love.load then love.load(love.arg.parseGameArguments(arg), arg) end
  if love.timer then love.timer.step() end
  local dt = 0
  return function()
    if love.event then
      love.event.pump()
      for name, a,b,c,d,e,f in love.event.poll() do
        if name == "quit" then
          if not love.quit or not love.quit() then
            return a or 0
          end
        end
        love.handlers[name](a,b,c,d,e,f)
      end
    end
    if love.timer then dt = love.timer.step() end
    accumulator = accumulator + dt
    if accumulator > rate then
      if love.update then love.update(rate) end
      if love.graphics and love.graphics.isActive() then
        love.graphics.origin()
        love.graphics.clear(love.graphics.getBackgroundColor())
        if love.draw then love.draw() end
        love.graphics.present()
      end
      accumulator = math.min(rate, accumulator - rate)
    end
    if love.timer then love.timer.sleep(0.001) end
  end
end