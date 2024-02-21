-- custom run (I think it may have been Elias who created this).
-- essentially just used to limit FPS to 60
-- anything higher is just wasted cycles on a game like this
require "run"
local flux = require "lib.flux"

local lg = love.graphics
lg.setDefaultFilter("nearest", "nearest")

local bg = lg.newImage("res/bg.png")

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

-- sound effects
local sfx = {
    ok = love.audio.newSource("res/ok.wav", "static"),
    no = love.audio.newSource("res/no.wav", "static"),
    match1 = love.audio.newSource("res/match1.wav", "static"),
    match5 = love.audio.newSource("res/match5.wav", "static"),
    matchcube = love.audio.newSource("res/matchcube.wav", "static"),
    win = love.audio.newSource("res/win.wav", "static"),
    fail = love.audio.newSource("res/fail.wav", "static"),
    welcome = love.audio.newSource("res/welcome.wav", "static")
}

-- tally table will store the score and attempts
-- it's reset inside newBoard()
local tally = {}

-- load the beautiful QuinqueFive font by ggbot
-- https://ggbot.itch.io/quinquefive-font
local font = lg.newFont("res/QuinqueFive.otf", 20)

local SCREEN_WIDTH = 384*4
local SCREEN_HEIGHT = 216*4

-- color stuff
local function hex_to_color(hex)
    return { tonumber("0x" .. hex:sub(1,2)) / 255,
           tonumber("0x" .. hex:sub(3,4)) / 255,
           tonumber("0x" .. hex:sub(5,6)) / 255 }
end

local pal = {
    bg = hex_to_color("0b152e"),
    hex = hex_to_color("444a86"),
    rune = hex_to_color("9cc1f7"),
    matched = hex_to_color("0e325c")
}

-- if the player can hover over hexagons and click on them
-- should be paused (false) during animations/tweening
local canMove = false

-- the arrow that does literally nothing
local arrow = {
    x = 694,
    y = 698,
    src = lg.newImage("res/arrow.png")
}

local hexSize = 32
local hexWidth = 84     --1.5 * hexSize * math.sqrt(3) .. you know what, I'll just fucking hardcode it in. come at me bro
local hexHeight = 2 * hexSize

local hexPolygon = {
    0, 0,
    hexWidth * 0.25, hexHeight * 0.5,
    hexWidth * 0.75, hexHeight * 0.5,
    hexWidth, 0,
    hexWidth * 0.75, -hexHeight * 0.5,
    hexWidth * 0.25, -hexHeight * 0.5
}

local difficulty = {
    [1] = {
        [1] = { 2, 2 },
        [2] = { 7, 3 },
        [3] = { 2, 7 },
        [4] = { 3, 11 },
        [5] = { 7, 11 },
        [6] = { 5, 7 }
    },

    [2] = {
        [1] = { 1, 2 },
        [2] = { 7, 2 },
        [3] = { 1, 7 },
        [4] = { 1, 12 },
        [5] = { 8, 11 },
        [6] = { 5, 7 }
    },

    [3] = {
        [1] = { 1, 1 },
        [2] = { 1, 7 },
        [3] = { 1, 11 },
        [4] = { 4, 9 },
        [5] = { 5, 5 },
        [6] = { 6, 2 },
        [7] = { 6, 12 }
    }
}

local level = 1
local totalRunes = 96
local runesReady = 0
local gameStarted = false
local levelSize = {
    reg = { 8, 12, 7 },
    large = { 8, 16, 9 }
}

local cursorShake = {x = 0, y = 0}

-- generates and returns a random level
-- pass it the number of rows, columns and min/max of runes to summon
function generateRandomLevel(rows, cols, minRunes, maxRunes)
    local level = {}
    local numberOfRunes = love.math.random(minRunes, maxRunes)
    
    while #level < numberOfRunes do
        local row = love.math.random(1, rows)
        local col = love.math.random(1, cols)
        
        -- check if the current position is too close to other runes
        if not isTooCloseToOtherRunes(level, row, col) then
            table.insert(level, {row, col})
        end
    end
    
    return level
end

-- helper function for detecting runes too close to others
function isTooCloseToOtherRunes(level, row, col)
    for _, rune in ipairs(level) do
        local distance = math.max(math.abs(rune[1] - row), math.abs(rune[2] - col))
        if distance < 2 then -- ensures there's at least one tile spacing!
            return true
        end
    end
    return false
end

-- set up grid
-- arguments: number of rows, number of columns, random level (bool)
function newBoard(nrows, ncols, rando)
    rows = nrows or 8
    cols = ncols or 12

    local lvlMap = rando and generateRandomLevel(rows, cols, 8, 12) or difficulty[level]
    local lsize = rando and levelSize.large or levelSize.reg
    if rando then
        arrow.x = 662 -- arrow.x -32
    end

    sfx.welcome:stop()
    sfx.welcome:play()
    gameStarted = false
    canMove = false
    runesReady = 0
    local modifier = rando and 8 or 6
    tally = {
        score = 0,
        moves = 10 + (#lvlMap - modifier), -- add 1 extra attempt for every rune over 6
        left = #lvlMap
    }
    -- yeah baby, give me those sexy globals

    totalRunes = rows * cols
    rows = rows + 1
    local xOffset = (SCREEN_WIDTH - cols * hexWidth * 0.92) / 2
    local yOffset = (SCREEN_HEIGHT - rows * hexHeight) / 2

    -- create the grid
    -- mark the special runes with type 6
    -- all others receive a random number between 1-4
    grid = {}
    for row = 1, rows-1 do
        grid[row] = {}
        for col = 1, cols do
            local x = (col - 1) * hexWidth * 0.75 + xOffset
            local y = (row - 1) * hexHeight + yOffset
            if col % 2 == 0 then
                y = y + hexHeight * 0.5
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
            grid[row][col] = { realx = x, realy = y, x = startx, y = starty, rune = runeType, row = row, col = col }
            flux.to(grid[row][col], 0.7, { x = grid[row][col].realx, y = grid[row][col].realy }):oncomplete(function()
                runesReady = runesReady + 1
            end):delay((rows - row) * 0.12)
        end
    end

    local specialRow = rows
    local specialCol = lsize[3]

    local x = (specialCol - 1) * hexWidth * 0.75 + xOffset
    local y = (specialRow - 1) * hexHeight + yOffset
    -- don't think I need this
    -- gonna leave it be just in case shit breaks
    --[[
    if cols % 2 == 0 then
        y = y - hexHeight * 0.5
    end]]
    
    grid[specialRow] = { [specialCol] = { x = x, y = y, rune = 5, row = specialRow, col = specialCol } }

    -- using a background image, so not really needed
    --lg.setBackgroundColor(pal.bg)
end

function love.load()
    lg.setFont(font)
    newBoard()
end

function love.update(dt)
    flux.update(dt)

    -- check to see if we've generated a new board and the runes
    -- have all fallen in to place
    if not gameStarted and runesReady >= totalRunes then
        gameStarted = true
        canMove = true
    end
end

-- print the moves left and current score to the top of the screen
function drawTally()
    lg.print("Attempts: " .. tally.moves, 540, 24)
    lg.print("Score: " .. tally.score, 540, 64)
end

function love.draw()
    lg.setColor(1, 1, 1, 1)
    lg.draw(bg, 0, 0)

    for row = 1, rows do
        for col = 1, cols do
            if grid[row][col] ~= nil then
                local x = grid[row][col].x
                local y = grid[row][col].y

                lg.push()
                lg.translate(x, y)

                -- if its rune type is 5 (matched), then fill in the hexagon
                -- with a solid color to make it stand out more
                -- thanks for the idea steve!
                if grid[row][col].rune == 5 then
                    lg.setColor(pal.matched)
                    lg.polygon('fill', hexPolygon)
                -- otherwise just draw the outline of the hexagon
                else
                    if grid[row][col].rune == 6 then
                        lg.setColor(1, 1, 1, 1)
                        lg.setLineWidth(2)
                    else
                        lg.setColor(pal.hex)
                        lg.setLineWidth(1)
                    end
                    lg.polygon('line', hexPolygon)
                end

                -- draw the rune sprite in the center of the hexagon
                lg.setColor(pal.rune)
                local runeX = (hexWidth - hexSize) / 2
                local runeY = (hexHeight - hexSize) / 2 - hexSize

                lg.draw(rune_sheet, runes[grid[row][col].rune], runeX, runeY)

                lg.pop()
            end
        end
    end

    -- draw an outline around the currently hovered over hexagon
    lg.setColor(1, 1, 1, 1)
    local hoveredHexagon = getHoveredHexagon()
    if hoveredHexagon then
        lg.push()
        lg.translate(hoveredHexagon.x, hoveredHexagon.y)

        lg.setColor(1, 1, 1, 1)
        lg.polygon('line', hexPolygon)

        lg.pop()
    end

    lg.draw(arrow.src, arrow.x, arrow.y)

    drawTally()
end

function getHoveredHexagon()
    if canMove then
        local mouseX, mouseY = love.mouse.getPosition()
        for row = 1, rows do
            for col = 1, cols do
                local hexagon = grid[row][col]
                if hexagon then
                    local x = hexagon.x
                    local y = hexagon.y

                    local yOffset = hexHeight / 2

                    if mouseX > x and mouseX < x + hexWidth * 0.75 and
                       mouseY > y - yOffset and mouseY < y + hexHeight - yOffset then
                        if col % 2 == 0 and mouseX < x + hexWidth * 0.25 then
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

function matchAdjacentHexagons(row, col, targetRune)
    if row < 1 or row > rows or col < 1 or col > cols or grid[row][col].rune ~= targetRune then
        return
    end

    grid[row][col].rune = 5

    -- position of hexagons
    local neighbors = {{-1, 0}, {-1, 1}, {0, -1}, {0, 1}, {1, -1}, {1, 0}}
    if col % 2 == 0 then
        neighbors = {{-1, -1}, {-1, 0}, {0, -1}, {0, 1}, {1, 0}, {1, 1}}
    end

    -- recursively check adjacent hexagons
    for _, offset in ipairs(neighbors) do
        local newRow = row + offset[1]
        local newCol = col + offset[2]
        matchAdjacentHexagons(newRow, newCol, targetRune)
    end
end

-- this function checks to see if we're touching a matching rune (5)
-- if not, you're unable to select the tile
function isTouchingRuneFive(row, col)
    local neighbors = getNeighbors(row, col)
    for _, neighbor in ipairs(neighbors) do
        local nRow, nCol = neighbor[1], neighbor[2]
        if grid[nRow][nCol] and grid[nRow][nCol].rune == 5 then
            return true
        end
    end

    sfx.no:stop()
    sfx.no:play()
    return false
end

function doWin()
    -- play victory sound
    love.audio.stop()
    sfx.win:play()

    -- add 5 points for every remaining move left
    tally.score = tally.score + (tally.left * 5)
end

function doLose()
    love.audio.stop()
    sfx.fail:play()
end

-- how many special runes we uncovered in a single turn
local matchedSpecial = 0

function love.mousepressed(x, y, button, istouch)
    if canMove and button == 1 then
        local clickedHexagon = getHoveredHexagon(x, y)
        if clickedHexagon and clickedHexagon.rune == 6 then
            sfx.no:stop()
            sfx.no:play()
            return
        end

        if clickedHexagon and isTouchingRuneFive(clickedHexagon.row, clickedHexagon.col) then
            local count = matchTiles(clickedHexagon.row, clickedHexagon.col, grid[clickedHexagon.row][clickedHexagon.col].rune)

            if matchedSpecial > 0 then
                tally.left = tally.left - matchedSpecial
                matchedSpecial = 0
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

            tally.moves = tally.moves - 1
            tally.score = tally.score + count

            if tally.moves == 0 and tally.left > 0 then
                doLose()
            
            elseif tally.left == 0 then
                doWin()
            end
        end
    end
end

-- recursive matching jank below
function matchTiles(row, col, runeType)
    if grid[row][col] then
        if row < 1 or row > rows or col < 1 or col > cols then
            return 0
        end

        if grid[row][col].rune ~= runeType or grid[row][col].rune == 5 then
            return 0
        end

        local neighbors = getNeighbors(row, col)
        for _, neighbor in ipairs(neighbors) do
            local nRow, nCol = neighbor[1], neighbor[2]
            if grid[nRow][nCol] then
                -- touched a special rune
                if grid[nRow][nCol].rune == 6 then
                    matchedSpecial = matchedSpecial + 1
                    grid[nRow][nCol].rune = 5
                end
            end
        end

        grid[row][col].rune = 5
        local count = 1

        for _, neighbor in ipairs(neighbors) do
            local nRow, nCol = neighbor[1], neighbor[2]
            count = count + matchTiles(nRow, nCol, runeType)
        end

        return count
    end
    return 0
end

function getNeighbors(row, col)
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
        if nRow >= 1 and nRow <= rows and nCol >= 1 and nCol <= cols then
            table.insert(valid_neighbors, neighbor)
        end
    end

    return valid_neighbors
end

function love.keypressed(key, sc)
    -- some basic shortcuts used primarily for testing, but I'll probably leave them in
    -- r will generate a random board
    -- number keys to generate a new board. the number being the difficulty level
    if canMove then
        if key == "r" then
            newBoard(8, 16, true)

        elseif key == "1" then
            level = 1
            newBoard()
        elseif key == "2" then
            level = 2
            newBoard()
        elseif key == "3" then
            level = 3
            newBoard()
        end
    end
end