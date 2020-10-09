--[[
    GD50
    Match-3 Remake

    -- PlayState Class --

    Author: Colton Ogden
    cogden@cs50.harvard.edu

    State in which we can actually play, moving around a grid cursor that
    can swap two tiles; when two tiles make a legal swap (a swap that results
    in a valid match), perform the swap and destroy all matched tiles, adding
    their values to the player's point score. The player can continue playing
    until they exceed the number of points needed to get to the next level
    or until the time runs out, at which point they are brought back to the
    main menu or the score entry menu if they made the top 10.
]]

PlayState = Class{__includes = BaseState}

clickX , clickY = 0, 0
canClickTile = false -- if mouse pressed and the click is inside the board range
mouse_pressed = false -- keeping track of mouse pressed action
clickGridX, clickGridY = 0, 0 -- gridX and gridY value calculated based on mouse click positions

function PlayState:init()
    
    -- start our transition alpha at full, so we fade in
    self.transitionAlpha = 1
    -- just a variable to store level of Y for the label
     self.levelLabelY = -64

    -- position in the grid which we're highlighting
    self.boardHighlightX = 0
    self.boardHighlightY = 0

    -- timer used to switch the highlight rect's color
    self.rectHighlighted = false

    -- flag to show whether we're able to process input (not swapping or clearing)
    self.canInput = true

    -- tile we're currently highlighting (preparing to swap)
    self.highlightedTile = nil

    self.score = 0
    self.timer = 60

    -- set our Timer class to turn cursor highlight on and off
    Timer.every(0.5, function()
        self.rectHighlighted = not self.rectHighlighted
    end)

    -- subtract 1 from timer every second
    Timer.every(1, function()
        self.timer = self.timer - 1

        -- play warning sound on timer if we get low
        if self.timer <= 5 then
            gSounds['clock']:play()
        end
    end)
end

function PlayState:enter(params)
    
    -- grab level # from the params we're passed
    self.level = params.level or 1

    -- spawn a board and place it toward the right
    self.board = params.board or Board(VIRTUAL_WIDTH - 2, 16, self.level)
    --self.board = params.board
    -- grab score from params if it was passed
    self.score = params.score or 0

    -- score we have to reach to get to the next level
    self.scoreGoal = self.level * 1.25 * 5000

end

function PlayState:update(dt)      

    -- get current positions and convert into push screen positions
    mouseX, mouseY =  clickX, clickY
    mouseX, mouseY = push:toGame(mouseX, mouseY)

    -- get gridX and gridY based on mouse click positions; to be used when getting tiles from the board
    self:mouseXYtoGridXY(mouseX, mouseY)

    -- check if mouse is pressed within the range of the board
    if mouse_pressed and (clickGridX > 0 and clickGridX < 9 and clickGridY > 0 and clickGridY < 9) then
        canClickTile = true
    else 
        canClickTile = false
    end 

    if love.keyboard.wasPressed('escape') then
        love.event.quit()
    end

    -- go back to start if time runs out
    if self.timer <= 0 then
        
        -- clear timers from prior PlayStates
        Timer.clear()
        
        gSounds['game-over']:play()

        gStateMachine:change('game-over', {
            score = self.score
        })
    end

    -- go to next level if we surpass score goal
    if self.score >= self.scoreGoal then
        
        -- clear timers from prior PlayStates
        -- always clear before you change state, else next state's timers
        -- will also clear!
        Timer.clear()

        gSounds['next-level']:play()

        -- change to begin game state with new level (incremented)
        gStateMachine:change('begin-game', {
            level = self.level + 1,
            score = self.score
        })
    end

    if self.canInput then

        -- move cursor around based on bounds of grid, playing sounds
        if love.keyboard.wasPressed('up') then
            self.boardHighlightY = math.max(0, self.boardHighlightY - 1)
            gSounds['select']:play()
        elseif love.keyboard.wasPressed('down') then
            self.boardHighlightY = math.min(7, self.boardHighlightY + 1)
            gSounds['select']:play()
        elseif love.keyboard.wasPressed('left') then
            self.boardHighlightX = math.max(0, self.boardHighlightX - 1)
            gSounds['select']:play()
        elseif love.keyboard.wasPressed('right') then
            self.boardHighlightX = math.min(7, self.boardHighlightX + 1)
            gSounds['select']:play()
        end

        -- if we've pressed enter, to select or deselect a tile...
        if love.keyboard.wasPressed('enter') or love.keyboard.wasPressed('return') or canClickTile then
            local x = 0
            local y = 0

            -- get highlight position based on either mouse click or cursor from keyboard keys
            if canClickTile then 
                x = clickGridX
                y = clickGridY
            else
                x = self.boardHighlightX + 1
                y = self.boardHighlightY + 1
            end
            
            -- if nothing is highlighted, highlight current tile
            if not self.highlightedTile then
                self.highlightedTile = self.board.tiles[y][x]

            -- if we select the position already highlighted, remove highlight
            elseif self.highlightedTile == self.board.tiles[y][x] then
                self.highlightedTile = nil

            -- if the difference between X and Y combined of this highlighted tile
            -- vs the previous is not equal to 1, also remove highlight
            elseif math.abs(self.highlightedTile.gridX - x) + math.abs(self.highlightedTile.gridY - y) > 1 then
                gSounds['error']:play()
                self.highlightedTile = nil
            else
                local newTile = self.board.tiles[y][x]
                self.highlightedTile, newTile = self:swapTiles(self.highlightedTile, newTile)

                -- tween coordinates between the two so they swap
                Timer.tween(0.1, {
                    [self.highlightedTile] = {x = newTile.x, y = newTile.y},
                    [newTile] = {x = self.highlightedTile.x, y = self.highlightedTile.y}
                })
                
                --once the swap is finished, we can tween falling blocks as needed
                :finish(function()
                    -- Only allow swapping when it results in a match. Else swap and revert it back, both in board and render
                    if self.board:calculateMatches() then
                        self:calculateMatches()

                    else
                        gSounds['error']:play()
                        self:swapTiles(self.highlightedTile, newTile)
                        Timer.tween(0.2, {
                            [self.highlightedTile] = {x = newTile.x, y = newTile.y},
                            [newTile] = {x = self.highlightedTile.x, y = self.highlightedTile.y}
                        })
                        self.highlightedTile = nil                        
                    end
                end)
            end
        end

    end
    mouse_pressed = false
    Timer.update(dt)
end

--[[
    Calculates whether any matches were found on the board and tweens the needed
    tiles to their new destinations if so. Also removes tiles from the board that
    have matched and replaces them with new randomized tiles, deferring most of this
    to the Board class.
]]
function PlayState:calculateMatches()
    self.highlightedTile = nil

    -- if we have any matches, remove them and tween the falling blocks that result
    local matches = self.board:calculateMatches()
    
    if matches then

        gSounds['match']:stop()
        gSounds['match']:play()

        -- add score for each match
        for k, match in pairs(matches) do
            -- score based on tile's variety 
            for i, tile in pairs(match) do 
                self.score = self.score + tile.variety * 50
            end
            -- add seconds to timer based on number of matched tiles made - 1 second per tile
            self.timer = self.timer + #match
        end

        -- remove any tiles that matched from the board, making empty spaces
        self.board:removeMatches()

        -- gets a table with tween values for tiles that should now fall
        local tilesToFall = self.board:getFallingTiles()

        -- if there are no possible matches in the board, keep resetting board until possibility is there
        while not self.board:checkMatchesPossible() do
            self.board:initializeTiles()

            -- a label to show 'resetting board' 
            -- transition label  from above
            Timer.tween(0.25, {
                [self] = {levelLabelY = VIRTUAL_HEIGHT / 2 - 8}
            })

            -- after that, pause for one second with Timer.after
            :finish(function()
                Timer.after(1, function()
                    -- then, animate the label going down past the bottom edge
                    Timer.tween(0.5, {
                        [self] = {levelLabelY = VIRTUAL_HEIGHT + 30}
                    })
                    
                end)
            end)
        end


        -- tween new tiles that spawn from the ceiling over 0.25s to fill in
        -- the new upper gaps that exist
        Timer.tween(0.25, tilesToFall):finish(function()
            
            -- recursively call function in case new matches have been created
            -- as a result of falling blocks once new blocks have finished falling
            self:calculateMatches()
        end)
        

    -- if no matches, we can continue playing
    else
        self.canInput = true
    end
end

function PlayState:swapTiles(highlightedTile, newTile)
    -- swap grid positions of tiles
    local tempX = highlightedTile.gridX
    local tempY = highlightedTile.gridY

    highlightedTile.gridX = newTile.gridX
    highlightedTile.gridY = newTile.gridY
    newTile.gridX = tempX
    newTile.gridY = tempY

    -- swap tiles in the tiles table
    self.board.tiles[highlightedTile.gridY][highlightedTile.gridX] =
        highlightedTile

    self.board.tiles[newTile.gridY][newTile.gridX] = newTile

    return highlightedTile, newTile
end

function PlayState:render()
    -- render board of tiles
    self.board:render()

    -- render highlighted tile if it exists
    if self.highlightedTile then
        
        -- multiply so drawing white rect makes it brighter
        love.graphics.setBlendMode('add')

        love.graphics.setColor(1, 1, 1, 96/255)
        love.graphics.rectangle('fill', (self.highlightedTile.gridX - 1) * 32 + (VIRTUAL_WIDTH - 272),
            (self.highlightedTile.gridY - 1) * 32 + 16, 32, 32, 4)

        -- back to alpha
        love.graphics.setBlendMode('alpha')
    end

    -- render highlight rect color based on timer
    if self.rectHighlighted then
        love.graphics.setColor(217/255, 87/255, 99/255, 255/255)
    else
        love.graphics.setColor(172/255, 50/255, 50/255, 255/255)
    end

    -- draw actual cursor rect
    love.graphics.setLineWidth(4)
    love.graphics.rectangle('line', self.boardHighlightX * 32 + (VIRTUAL_WIDTH - 272),
        self.boardHighlightY * 32 + 16, 32, 32, 4)

    -- GUI text
    love.graphics.setColor(56/255, 56/255, 56/255, 234/255)
    love.graphics.rectangle('fill', 16, 16, 186, 116, 4)

    love.graphics.setColor(99/255, 155/255, 255/255, 255/255)
    love.graphics.setFont(gFonts['medium'])
    love.graphics.printf('Level: ' .. tostring(self.level), 20, 24, 182, 'center')
    love.graphics.printf('Score: ' .. tostring(self.score), 20, 52, 182, 'center')
    love.graphics.printf('Goal : ' .. tostring(self.scoreGoal), 20, 80, 182, 'center')
    love.graphics.printf('Timer: ' .. tostring(self.timer), 20, 108, 182, 'center')

    -- render Level # label and background rect
    love.graphics.setColor(95/255, 205/255, 228/255, 200/255)
    love.graphics.rectangle('fill', 0, self.levelLabelY - 8, VIRTUAL_WIDTH, 48)
    love.graphics.setColor(255/255, 255/255, 255/255, 255/255)
    love.graphics.setFont(gFonts['medium'])
    love.graphics.printf('...Resetting Board...',
        0, self.levelLabelY + 7, VIRTUAL_WIDTH, 'center')

    -- GUI to show hint
    love.graphics.setColor(56/255, 56/255, 56/255, 234/255)
    love.graphics.rectangle('fill', 16, VIRTUAL_HEIGHT - 56, 192, 32, 4)
    love.graphics.setColor(99/255, 155/255, 255/255, 255/255)
    love.graphics.printf("HINT: " .. tostring(hint), 20, VIRTUAL_HEIGHT - 48, VIRTUAL_WIDTH, "left")
end

function love.mousepressed(x, y, button, istouch)
   if button == 1 then -- Versions prior to 0.10.0 use the MouseConstant 'l'
      clickX = x
      clickY = y
      mouse_pressed = true
   end
end

-- get gridX and gridY based on mouse click positions (pushed to the game area)
function PlayState:mouseXYtoGridXY(mouseX, mouseY)
    -- 240 is the offset of board from left
    -- 16 is the offset of board from top
    clickGridX = math.ceil((mouseX - 240) / 32)
    clickGridY = math.ceil((mouseY - 16) / 32)
end