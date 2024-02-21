local Scene = require "lib.Scene"

local Title = Scene:extends()

local screenWidth, screenHeight = 384*4, 216*4

local bg = love.graphics.newImage("res/bg.png")
local navarrow = {
    src = love.graphics.newImage("res/navarrow.png"),
    pos = 1
}

local font = {
    title = love.graphics.newFont("res/bump-it-up.otf", 48),
    nav = love.graphics.newFont("res/bump-it-up.otf", 24)
}

local sfx = {
    click = love.audio.newSource("res/navclick.wav", "static"),
    move = love.audio.newSource("res/navmove.wav", "static")
}

local numberOfSides = 6

function Title:new()
    self.rotationAngle = 0
end

function Title:on_enter()
    self.active = 1
end

function Title:update(dt)
    self.rotationAngle = self.rotationAngle + dt * 0.2
end

function Title:drawHexagon(x, y, radius, angle)
    love.graphics.push()
    love.graphics.translate(x, y)
    love.graphics.rotate(angle)

    for i = 1, numberOfSides do
        local theta = (2 * math.pi / numberOfSides) * (i - 1)
        local nextTheta = (2 * math.pi / numberOfSides) * i
        local px1, py1 = radius * math.cos(theta), radius * math.sin(theta)
        local px2, py2 = radius * math.cos(nextTheta), radius * math.sin(nextTheta)
        
        love.graphics.line(px1, py1, px2, py2)
    end

    love.graphics.pop()
end

local navcol = {
    active = { 1, 1, 1 },
    hidden = { 0.64313725490196, 0.78823529411765, 0.75686274509804 }
}
function Title:drawNav()
    love.graphics.setFont(font.nav)

    love.graphics.setColor(0, 0, 0)
    love.graphics.print("Adventure Mode", 84, 504)
    love.graphics.setColor(self.active == 1 and navcol.active or navcol.hidden)
    love.graphics.print("Adventure Mode", 80, 500)

    love.graphics.setColor(0, 0, 0)
    love.graphics.print("     Endless Mode", 84, 544)
    love.graphics.setColor(self.active == 2 and navcol.active or navcol.hidden)
    love.graphics.print("     Endless Mode", 80, 540)

    love.graphics.setColor(0, 0, 0)
    love.graphics.print("                      Quit", 84, 584)
    love.graphics.setColor(self.active == 3 and navcol.active or navcol.hidden)
    love.graphics.print("                      Quit", 80, 580)

    love.graphics.draw(navarrow.src, 440, 460 + (40 * self.active))
end

function Title:draw()
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.draw(bg, 0, 0)

    local hexagonRadius = screenHeight / 4 
    local x, y = screenWidth / 2, screenHeight / 2

    for i = 1, 5 do
        local scale = 1 - (i - 1) * 0.1
        local adjustedRadius = hexagonRadius * scale
        local adjustedAngle = self.rotationAngle + (i - 1) * 0.05
        love.graphics.setColor(0.53725490196078,0.55294117647059,0.9843137254902, 1 - (i - 1) * 0.2)
        self:drawHexagon(x, y, adjustedRadius, adjustedAngle)
    end

    -- Title
    love.graphics.setFont(font.title)
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.print("Scry", 660, 400)

    self:drawNav()
end

function Title:keypressed(key, sc)
    if key == "down" then
        sfx.move:stop()
        sfx.move:play()
        self.active = self.active + 1

        if self.active == 4 then self.active = 1 end
    elseif key == "up" then
        sfx.move:stop()
        sfx.move:play()
        self.active = self.active - 1
        if self.active == 0 then self.active = 3 end
    end
end

return Title