local Scene = require "lib.Scene"

local Game = Scene:extends()

-- load rxi's AMAZING tweening library
local flux = require "lib.flux"

local R3 = require "lib.R3"

-- shortcut to love.graphics seems we use it alot
local lg = love.graphics

-- background image
local bg = lg.newImage("res/woods_bg.png")
local bgm = love.audio.newSource("res/bgm/woods/2.ogg", "stream")
bgm:setVolume(0.60)

local SCREEN_WIDTH = 384*4
local SCREEN_HEIGHT = 216*4

-- rune sprite stuff
local rune_sheet = lg.newImage("res/runes.png")
local runes = {
    [1] = lg.newQuad(0, 0, 32, 32, rune_sheet:getDimensions()),
    [2] = lg.newQuad(32, 0, 32, 32, rune_sheet:getDimensions()),
    [3] = lg.newQuad(64, 0, 32, 32, rune_sheet:getDimensions()),
    [4] = lg.newQuad(96, 0, 32, 32, rune_sheet:getDimensions()),
    [5] = lg.newQuad(128, 0, 32, 32, rune_sheet:getDimensions()),
    [6] = lg.newQuad(160, 0, 32, 32, rune_sheet:getDimensions())
}

local banner = {
    success = lg.newImage("res/success.png"),
    x = 0,
    y = -SCREEN_HEIGHT
}

local cubePoints = {
    { 1,  1,  1 },
    { 1,  1,  -1 },
    { 1,  -1, -1 },
    { 1,  -1, 1 },
    { -1, 1,  1 },
    { -1, 1,  -1 },
    { -1, -1, -1 },
    { -1, -1, 1 },
}

local cubeLines = {
    1, 2,
    2, 3,
    3, 4,
    4, 1,
    5, 6,
    6, 7,
    7, 8,
    8, 5,
    1, 5,
    2, 6,
    3, 7,
    4, 8
}
for i, n in ipairs(cubeLines) do
    cubeLines[i] = (n - 1) * 2 + 1
end

local cubeSize = 10

-- sound effects
local sfx = {
    ok = love.audio.newSource("res/ok.wav", "static"),
    no = love.audio.newSource("res/no.wav", "static"),
    match1 = love.audio.newSource("res/match1.wav", "static"),
    match5 = love.audio.newSource("res/match5.wav", "static"),
    matchcube = love.audio.newSource("res/matchcube.wav", "static"),
    win = love.audio.newSource("res/win.wav", "static"),
    fail = love.audio.newSource("res/fail.wav", "static"),
    welcome = love.audio.newSource("res/welcome.wav", "static"),
    click = love.audio.newSource("res/navclick.wav", "static"),
    back = love.audio.newSource("res/return.wav", "static"),
    esc = love.audio.newSource("res/esc.wav", "static"),
    letter = love.audio.newSource("res/letter.wav", "static"),
    decoding = love.audio.newSource("res/decoding.wav", "static")
}

local uiFont = lg.newFont("res/bump-it-up.otf", 20)

local loreFontS = lg.newFont("res/ABeeZee.ttf", 24)
local loreFontL = lg.newFont("res/ABeeZee.ttf", 36)

-- color stuff
local function hex_to_color(hex)
    return { tonumber("0x" .. hex:sub(1,2)) / 255,
           tonumber("0x" .. hex:sub(3,4)) / 255,
           tonumber("0x" .. hex:sub(5,6)) / 255 }
end

local pal = {
    bg = hex_to_color("0b152e"),
    hex = hex_to_color("444a86"),
    cube = hex_to_color("4affd2"),
    rune = hex_to_color("f23e9a"),
    matched = hex_to_color("0e325c"),
    zycon = hex_to_color("0c9688")
}

-- the arrow that does literally nothing
local arrow = {
    x = 694,
    y = 698,
    src = lg.newImage("res/arrow.png")
}

local elements = {
    [1] = lg.newImage("res/hex_green.png"),
    [2] = lg.newImage("res/hex_stone.png"),
    [3] = lg.newImage("res/hex_water.png"),
    [4] = lg.newImage("res/hex_wood.png"),
    [5] = lg.newImage("res/hex_five.png"),
    [6] = lg.newImage("res/hex_special.png")
}

local totem = {
    src = lg.newImage("res/key.png"),
    x = 16,
    y = 76,
    bobY = 0,
    bobAmp = 10,
    bobPeriod = 1,
    bob_t = 0
}

local hex_uncovered = lg.newImage("res/hex_uncovered.png")

-- first 3 static levels
-- afterwards, the levels are randomly generated with larger boards
local difficulty = {
    [1] = {
        [1] = { 2, 2 },
        [2] = { 7, 3 },
        [3] = { 2, 7 },
        [4] = { 3, 11 },
        [5] = { 7, 11 },
        [6] = { 5, 7 },
        lore = [[
Rivenrock, once a bustling metropolis, now standing in ruins.
It's said that beneath its streets lies the Undervault, a repository of lost knowledge and forbidden technology.]]
    },

    [2] = {
        [1] = { 1, 2 },
        [2] = { 7, 2 },
        [3] = { 1, 7 },
        [4] = { 1, 12 },
        [5] = { 8, 11 },
        [6] = { 5, 7 },
        lore = [[
Crystal Caverns is a labyrinth of glowing tunnels, home to the Crystal Sentinels.
These guardians protect the Corelight Gem, a source of pure energy that sustains life in the darkest depths.]]
    },

    [3] = {
        [1] = { 1, 1 },
        [2] = { 1, 7 },
        [3] = { 1, 11 },
        [4] = { 4, 9 },
        [5] = { 5, 5 },
        [6] = { 6, 2 },
        [7] = { 6, 12 },
        lore = [[
The Skyward Isles, floating islands adrift in the sky, reachable only by those who master the winds.
The Skyward Library, nestled among the clouds, contains the wisdom of the ages.]]
    },

     [4] = {
        [1] = { 2, 8 },
        [2] = { 4, 10 },
        [3] = { 6, 12 },
        [4] = { 2, 4 },
        [5] = { 4, 2 },
        [6] = { 7, 1 },
        lore = [[
The Ember Sands, a desert with sands of smoldering ember, rumored to be the remnants of a cataclysmic fire spell.
The Phoenix Forge, buried beneath a dune, crafts weapons imbued with elemental fury.]]
    },

    [5] = {
        [1] = { 2, 10 },
        [2] = { 4, 12 },
        [3] = { 6, 7 },
        [4] = { 8, 10 },
        [5] = { 8, 3 },
        [6] = { 4, 1 },
        [7] = { 2, 4 },
        lore = [[
Frostbound Reach is a land forever locked in ice, home to the Virglas Obelisk.
It's said to be a key to unlocking eternal winter to its surrounding environment.]]
    },

    [6] = {
        [1] = { 1, 11 },
        [2] = { 4, 9 },
        [3] = { 8, 12 },
        [4] = { 5, 2 },
        [5] = { 1, 2 },
        lore = [[
The Shadowed Marshes, swamps shrouded in perpetual twilight, where the Moonlit Altar stands.
It's a place of power where the veil between worlds is thin.]]
    },
}

local cursorShake = {x = 0, y = 0}

-- small function to check for chance percentages
-- returns true or false
local function chance(percentage)
    local roll = love.math.random(1, 100)
    return roll <= percentage
end

function Game:new()
    -- tally table will store the score and attempts
    -- it's reset inside Game:newBoard()
    self.tally = { total = 0 }

    -- if the game needs to be paused, set this to false
    -- it will disallow the player to select any tiles
    self.canMove = false

    -- some game setup variables
    self.hexSize = 32
    self.hexWidth = 84     --1.5 * hexSize * math.sqrt(3)
    self.hexHeight = 2 * self.hexSize

    self.level = 1
    self.totalRunes = 96
    self.runesReady = 0
    self.matchedSpecial = 0
    self.gameStarted = false
    -- { rows, cols, starting point }
    self.levelSize = {
        reg = { 8, 12, 7 },
        large = { 8, 16, 9 }
    }
    -- store the hexagon shape for rendering
    self.hexPolygon = {
        0, 0,
        self.hexWidth * 0.25, self.hexHeight * 0.5,
        self.hexWidth * 0.75, self.hexHeight * 0.5,
        self.hexWidth, 0,
        self.hexWidth * 0.75, -self.hexHeight * 0.5,
        self.hexWidth * 0.25, -self.hexHeight * 0.5
    }

    self.loreAlpha = 0

    self.drawBoard = true
end

-- helper function for detecting runes too close to others
local function isTooCloseToOtherRunes(level, row, col)
    for _, rune in ipairs(level) do
        local distance = math.max(math.abs(rune[1] - row), math.abs(rune[2] - col))
        if distance < 2 then -- ensures there's at least one tile spacing!
            return true
        end
    end
    return false
end

-- generates and returns a random level
-- pass it the number of rows, columns and min/max of runes to summon
function Game:generateRandomLevel(rows, cols, minRunes, maxRunes)
    local level = {}
    local numberOfRunes = love.math.random(minRunes, maxRunes)
    
    while #level < numberOfRunes do
        local row = love.math.random(1, self.rows)
        local col = love.math.random(1, self.cols)
        
        -- check if the current position is too close to other runes
        if not isTooCloseToOtherRunes(level, row, col) then
            table.insert(level, {row, col})
        end
    end
    
    return level
end

-- set up grid
-- arguments: number of rows, number of columns, random level (bool)
function Game:newBoard(nrows, ncols, rando)
    self.gameOver = false
    self.showSuccess = false
    self.zycon = false

    self.rows = nrows or 8
    self.cols = ncols or 12

    local lvlMap = rando and self:generateRandomLevel(nrows, ncols, 8, 12) or difficulty[self.level]
    local lsize = rando and self.levelSize.large or self.levelSize.reg
    if rando then
        arrow.x = 662 -- arrow.x -32
    end

    sfx.welcome:stop()
    sfx.welcome:play()
    self.gameStarted = false
    self.canMove = false
    self.runesReady = 0
    local modifier = rando and 8 or 6
    self.tally = {
        score = 0,
        moves = 10 + (#lvlMap - modifier), -- add 1 extra attempt for every rune over 6
        left = #lvlMap,
        total = self.tally.total
    }

    -- store the max tally for later (this value won't be adjusted)
    self.tally.totalMoves = self.tally.moves

    self.totalRunes = self.rows * self.cols
    self.specialRunes = {}
    self.rows = self.rows + 1
    local xOffset = (SCREEN_WIDTH - self.cols * self.hexWidth * 0.92) / 2
    local yOffset = (SCREEN_HEIGHT - self.rows * self.hexHeight) / 2

    -- create the grid
    -- mark the special runes with type 6
    -- all others receive a random number between 1-4
    self.grid = {}
    for row = 1, self.rows-1 do
        self.grid[row] = {}
        for col = 1, self.cols do
            local x = (col - 1) * self.hexWidth * 0.75 + xOffset
            local y = (row - 1) * self.hexHeight + yOffset
            if col % 2 == 0 then
                y = y + self.hexHeight * 0.5
            end

            local runeType = 0
            
            for _,t in ipairs(lvlMap) do
                if row == t[1] and col == t[2] then
                    runeType = 6
                end
            end

            runeType = runeType == 6 and 6 or love.math.random(1, 4)
            -- pick a random start zone
            local startx = love.math.random(1, 2) == 1 and -84 or SCREEN_WIDTH
            local starty = love.math.random(-84, SCREEN_HEIGHT+84)
            self.grid[row][col] = { realx = x, realy = y, x = startx, y = starty, rune = runeType, row = row, col = col }
            flux.to(self.grid[row][col], 0.7, { x = self.grid[row][col].realx, y = self.grid[row][col].realy }):oncomplete(function()
                self.runesReady = self.runesReady + 1
            end):delay((self.rows - row) * 0.12)

            if runeType == 6 then
                table.insert(self.specialRunes, self.grid[row][col])
            end
        end
    end

    local specialRow = self.rows
    local specialCol = lsize[3]

    local x = (specialCol - 1) * self.hexWidth * 0.75 + xOffset
    local y = (specialRow - 1) * self.hexHeight + yOffset
    -- don't think I need this
    -- gonna leave it be just in case shit breaks
    --[[
    if self.cols % 2 == 0 then
        y = y - hexHeight * 0.5
    end]]
    
    self.grid[specialRow] = { [specialCol] = { x = x, y = y, rune = 5, uncovered = true, row = specialRow, col = specialCol } }

    -- using a background image, so not really needed
    --lg.setBackgroundColor(pal.bg)
end

local gems = {
    x = 700,
    y = 27,
    spacing = 21,
    srcVisible = lg.newImage("res/diamond.png"),
    srcHidden = lg.newImage("res/diamond_hidden.png")
}

local function print_s(str, x, y)
    lg.setColor(0, 0, 0)
    lg.print(str, x+2, y+2)
    lg.setColor(1, 1, 1, 1)
    lg.print(str, x, y)
end

function Game:drawMoveCounter()
    lg.setFont(uiFont)
    print_s("Moves:    ", 540, 24)
    for i = 1, self.tally.totalMoves do
        local x = gems.x + (i-1) * gems.spacing
        if i <= self.tally.moves then
            lg.draw(gems.srcVisible, x, gems.y)
        else
            lg.draw(gems.srcHidden, x, gems.y)
        end
    end
end

-- print the moves left and current score to the top of the screen
function Game:drawTally()
    --lg.print("Moves:    " .. self.tally.moves, 540, 24)
    self:drawMoveCounter()
    lg.setFont(uiFont)
    print_s("Score:  " .. self.tally.score, 540, 64)
    print_s("Level:  " .. self.level, 1020, 24)
    print_s("Total:  " .. self.tally.total, 540, 800)
end

function Game:on_enter(gameType)
    -- 1 = adventure mode
    -- 2 = endless
    self.gameType = gameType
    -- reset level to 1
    self.level = 1
    -- reset total score
    -- we only want to do that when we enter the game scene
    self.tally.total = 0
end

function Game:update(dt)
    flux.update(dt)

    if not self.gameStarted and self.runesReady >= self.totalRunes then
        self.gameStarted = true
        self.canMove = true
        -- music should start playing here I think
        -- commenting out for now while testing other features
        --bgm:play()
    end

    -- make the totems bob up and down
    totem.bob_t = totem.bob_t + dt
    local bobbing = math.sin(totem.bob_t * math.pi / totem.bobPeriod) * totem.bobAmp
    totem.bobY = totem.y + bobbing
end

function Game:draw()
    lg.setColor(1, 1, 1, 1)
    lg.draw(bg, 0, 0)

    if self.drawBoard then
        
        for _, r in ipairs(self.specialRunes) do
            lg.push()
            lg.translate(r.x, r.y)
            lg.setColor(1, 1, 1, 1 - (r.uncoverAnim or 0))
            lg.setLineWidth(2)
            --lg.polygon('line', self.hexPolygon)
            lg.draw(elements[6], 0, -self.hexHeight/2)
            lg.pop()
        end

        for row = 1, self.rows do
            for col = 1, self.cols do
                if self.grid[row][col] ~= nil then
                    local rune = self.grid[row][col]
                    local x = rune.x
                    local y = rune.y
                    local runeX = (self.hexWidth - self.hexSize) / 2
                    local runeY = (self.hexHeight - self.hexSize) / 2 - self.hexSize

                    lg.push()
                    lg.translate(x, y)

                    if rune.uncovered then
                        -- if its rune is uncovered, then fill in the hexagon
                        -- with a solid color to make it stand out more
                        -- thanks for the idea steve!
                        lg.push()
                        -- lg.translate(0, -self.hexHeight / 2)
                        lg.scale(1, rune.uncoverAnim or 1)
                        lg.setColor(rune.zycon and pal.zycon or pal.matched)
                        --lg.polygon('fill', self.hexPolygon)
                        --lg.setColor(pal.rune)
                        lg.setColor(1, 1, 1, 1)
                        lg.draw(hex_uncovered, 0, -(self.hexHeight/2))
                        --lg.draw(rune_sheet, runes[5], runeX, runeY)
                        lg.pop()
                    end
                    
                    if rune.rune ~= 6 and (not rune.uncovered or not rune.uncoverAnim or rune.uncoverAnim < 1) then
                        lg.setLineWidth(1)
                        lg.setColor(1, 1, 1, 1)
                        --lg.polygon('line', self.hexPolygon)
                        -- draw the rune sprite in the center of the hexagon
                        --lg.setColor(pal.rune)
                        
                        lg.draw(elements[rune.rune], 0, -(self.hexHeight/2))
                        lg.draw(rune_sheet, runes[rune.rune], runeX, runeY)

                    end

                    if rune.rune == 6 and (not rune.uncoverAnim or rune.uncoverAnim < 1) then
                        lg.draw(totem.src, totem.x, -totem.bobY)
                    end


                    lg.pop()
                end
            end
        end
    end

    -- draw an outline around the currently hovered over hexagon
    lg.setColor(1, 1, 1, 1)
    if not self.gameOver then
        local hoveredHexagon = self:getHoveredHexagon()
        if hoveredHexagon then
            lg.push()
            lg.translate(hoveredHexagon.x + cursorShake.x * math.sin(love.timer.getTime() * 60),
                hoveredHexagon.y + cursorShake.y * math.sin(love.timer.getTime() * 60))

            lg.setColor(1, 1, 1, 1)
            lg.polygon('line', self.hexPolygon)

            lg.pop()
        end
    end

    lg.draw(arrow.src, arrow.x, arrow.y)

    self:drawTally()

    if self.gameOver then
        if self.showSuccess then
            lg.draw(banner.success, banner.x, banner.y)
        end
    end

    if self.loreAlpha > 0 then
        lg.setColor(0, 0, 0.1, self.loreAlpha)
        lg.rectangle("fill", 0, 0, lg.getDimensions())
        lg.setFont(loreFontS)
        lg.setColor(1, 1, 1, self.loreAlpha * (math.floor(self.loreTitleFlash) % 2 == 0 and 0.5 or 1))
        lg.print(("Decoding record #%d..."):format(self.level - 1), 80, 80 - (1 - self.loreAlpha) * 80)
        lg.setFont(loreFontL)
        lg.setColor(1, 1, 1, self.loreAlpha)
        lg.printf(self.lore:sub(1, self.loreSubstr) .. (math.floor(love.timer.getTime() * 3) % 2 == 0 and "_" or ""), 80, 80 + loreFontS:getHeight() + 20, lg.getWidth() - 80 * 2, "left")
    end
end

function Game:getHoveredHexagon()
    if self.canMove then
        local mouseX, mouseY = love.mouse.getPosition()
        for row = 1, self.rows do
            for col = 1, self.cols do
                local hexagon = self.grid[row][col]
                if hexagon then
                    local x = hexagon.x
                    local y = hexagon.y

                    local yOffset = self.hexHeight / 2

                    if mouseX > x and mouseX < x + self.hexWidth * 0.75 and
                       mouseY > y - yOffset and mouseY < y + self.hexHeight - yOffset then
                        if col % 2 == 0 and mouseX < x + self.hexWidth * 0.25 then
                            return nil
                        end
                        return hexagon
                    end
                end
            end
        end
        return nil
    end
end

function Game:matchAdjacentHexagons(row, col, targetRune)
    if row < 1 or row > self.rows or col < 1 or col > self.cols or self.grid[row][col].rune ~= targetRune then
        return
    end

    self.grid[row][col].uncovered = true

    -- position of hexagons
    local neighbors = {{-1, 0}, {-1, 1}, {0, -1}, {0, 1}, {1, -1}, {1, 0}}
    if col % 2 == 0 then
        neighbors = {{-1, -1}, {-1, 0}, {0, -1}, {0, 1}, {1, 0}, {1, 1}}
    end

    -- recursively check adjacent hexagons
    for _, offset in ipairs(neighbors) do
        local newRow = row + offset[1]
        local newCol = col + offset[2]
        self:matchAdjacentHexagons(newRow, newCol, targetRune)
    end
end

-- this function checks to see if we're touching a matching rune (5)
-- if not, you're unable to select the tile
function Game:isTouchingRuneFive(row, col)
    local neighbors = self:getNeighbors(row, col)
    for _, neighbor in ipairs(neighbors) do
        local nRow, nCol = neighbor[1], neighbor[2]
        if self.grid[nRow][nCol] and self.grid[nRow][nCol].uncovered then
            return true
        end
    end

    self:doNo()
    return false
end

function Game:doWin()
    -- play victory sound
    love.audio.stop()
    sfx.win:play()

    -- add 5 points for every remaining move left
    self.tally.score = self.tally.score + (self.tally.moves * 5)
    self.tally.total = self.tally.total + self.tally.score
    self.gameOver = true
    self.showSuccess = true
    flux.to(banner, 1, { x = 0, y = 0 }, "cubicin")
end

function Game:doLose()
    love.audio.stop()
    sfx.fail:play()
    if self.gameType == 1 and self.level <= #difficulty then
        self:newBoard()
    else
        self:newBoard(8, 16, true)
    end
end

function Game:doNo()
    sfx.no:stop()
    sfx.no:play()
    cursorShake.x = 10
    flux.to(cursorShake, 0.4, {x = 0})
end

function Game:generateNextBoard()
    -- if the current level is greater than the number of levels in adventure mode
    -- then set the game type to endless
    if self.level > #difficulty then
        self.gameType = 2
        self:newBoard(8, 16, true)
    else
        self:newBoard()
    end
end

function Game:mousepressed(x, y, button, istouch)
    if self.loreAlpha > 0 then
        flux.to(self, 0.5, { loreAlpha = 0 }):oncomplete(function()
            self:generateNextBoard()
            self.drawBoard = true
        end)
        return
    end
    if self.canMove and not self.gameOver and button == 1 then
        local clickedHexagon = self:getHoveredHexagon()
        if clickedHexagon and (clickedHexagon.rune == 6 or clickedHexagon.uncovered) then
            self:doNo()
            return
        end

        if clickedHexagon and self:isTouchingRuneFive(clickedHexagon.row, clickedHexagon.col) then
            local count = self:matchTiles(clickedHexagon.row, clickedHexagon.col, self.grid[clickedHexagon.row][clickedHexagon.col].rune)

            if self.matchedSpecial > 0 then
                self.tally.left = self.tally.left - self.matchedSpecial
                self.matchedSpecial = 0
                sfx.matchcube:stop()
                sfx.matchcube:play()
            else
                if count == 1 then
                    sfx.match1:stop()
                    sfx.match1:play()
                elseif count > 1 and count < 6 then
                    sfx.ok:stop()
                    sfx.ok:play()
                elseif count >= 6 then
                    sfx.match5:stop()
                    sfx.match5:play()
                end
            end

            self.tally.moves = self.tally.moves - 1
            self.tally.score = self.tally.score + count

            if self.tally.moves == 0 and self.tally.left > 0 then
                self:doLose()
            
            elseif self.tally.left == 0 then
                self:doWin()
            --[[else
                -- TODO: Finish the Zycon
                -- if we haven't won or lost, we have a chance to spawn a Zycon
                if not self.zycon and chance(80) then self:spawnZycon() end]]
            end
        end
    elseif self.showSuccess then
        if x >= 578 and x <= 578+390 and y >= 486 and y <= 486+89 then
            sfx.click:stop()
            sfx.click:play()
            flux.to(banner, 0.3, { y = -SCREEN_HEIGHT }, "cubicin"):oncomplete(function()
                self.level = self.level + 1
                -- if we're playing adventure mode
                if self.gameType == 1 then
                    if difficulty[self.level - 1].lore then
                        sfx.decoding:play()

                        -- show lore before generating the board
                        self.lore = difficulty[self.level - 1].lore
                        flux.to(self, 0.5, { loreAlpha = 1 }):oncomplete(function()
                            self.drawBoard = false
                        end)
                        self.loreSubstr = 0
                        flux.to(self, #self.lore / 50, { loreSubstr = #self.lore }):delay(1.2):ease("linear")
                            :onupdate(function() if self.showSuccess then sfx.letter:play() end end)

                        self.loreTitleFlash = 0
                        flux.to(self, 1, { loreTitleFlash = 11 }):ease("linear")
                    else
                        self:generateNextBoard()
                    end
                -- otherwise we must be playing endless, so generate a random board
                else
                    self:newBoard(8, 16, true)
                end
            end)
        end
    end
end

-- recursive matching jank below
function Game:matchTiles(row, col, runeType, depth)
    depth = depth or 0
    local node = self.grid[row][col]
    if node then
        if row < 1 or row > self.rows or col < 1 or col > self.cols then
            return 0
        end

        if (node.rune ~= runeType and node.rune ~= 6) or node.uncovered then
            return 0
        end

        local neighbors = self:getNeighbors(row, col)
        
        node.uncovered = true
        node.uncoverAnim = 0
        flux.to(node, node.rune == 6 and 0.4 or 0.2, { uncoverAnim = 1 }):delay(depth * 0.05)
        local count = 1

        if node.rune == 6 then
            -- touched a special rune
            self.matchedSpecial = self.matchedSpecial + 1
            node.uncovered = true
        else
            for _, neighbor in ipairs(neighbors) do
                local nRow, nCol = neighbor[1], neighbor[2]
                count = count + self:matchTiles(nRow, nCol, runeType, depth + 1)
            end
        end

        return count
    end
    return 0
end

function Game:getNeighbors(row, col)
    local neighbors = {}

    -- i uh.. think this works??
    if col % 2 == 1 then
        neighbors = {
            {row - 1, col},     -- top
            {row + 1, col},     -- bottom
            {row, col - 1},     -- left
            {row, col + 1},     -- right
            {row - 1, col - 1}, -- top left
            {row - 1, col + 1}  -- top right
        }
    else
        neighbors = {
            {row - 1, col},     -- top
            {row + 1, col},     -- bottom
            {row, col - 1},     -- left
            {row, col + 1},     -- right
            {row + 1, col - 1}, -- bottom left
            {row + 1, col + 1}  -- bottom right
        }
    end

    local valid_neighbors = {}
    for _, neighbor in ipairs(neighbors) do
        local nRow, nCol = neighbor[1], neighbor[2]
        if nRow >= 1 and nRow <= self.rows and nCol >= 1 and nCol <= self.cols then
            table.insert(valid_neighbors, neighbor)
        end
    end

    return valid_neighbors
end

-- The zycon is a super special rune that has a percentage chance of spawning per move
-- if you manage to uncover it, you're awarded 50 points
function Game:spawnZycon()
    local zyconRevealed = false
    -- loop until we find a place for it
    while not zyconRevealed do
        -- we need to locate an uncovered tile to occupy
        -- and ensure there is a valid path to it
        local row, col = love.math.random(1, self.rows), love.math.random(1, self.cols)
        if self.grid[row][col] and self.grid[row][col].uncovered then
            local neighbors = self:getNeighbors(row, col)

            for _, neighbor in ipairs(neighbors) do
                local nTile = self.grid[neighbor[1]][neighbor[2]]
                -- make sure the neighbor tile is a standard rune so we can access the zycon from it
                if nTile and (nTile.rune == 1 or nTile.rune == 2 or nTile.rune == 3 or nTile.rune == 4) then
                    zyconRevealed = nTile
                    zyconRevealed.zycon = true
                    break
                end
            end
        end
    end

    self.zycon = zyconRevealed
    return zyconRevealed
end

local escLastPressed = love.timer.getTime()

function Game:keypressed(key, sc)
    -- some basic shortcuts used primarily for testing, but I'll probably leave them in
    -- r will generate a random board
    -- number keys to generate a new board. the number being the difficulty level
    if self.canMove then
        if key == "r" then
            self:newBoard(8, 16, true)

        elseif key == "1" then
            self.level = 1
            self:newBoard()
        elseif key == "2" then
            self.level = 2
            self:newBoard()
        elseif key == "3" then
            self.level = 3
            self:newBoard()

        -- press escape twice within a second to go back to title
        elseif key == "escape" then
            local gt = love.timer.getTime()
            if escLastPressed+1 > gt then
                sfx.back:play()
                SceneMgr:switch("Title")
            else
                sfx.esc:stop()
                sfx.esc:play()
                escLastPressed = gt
            end
        end
    end
end

return Game