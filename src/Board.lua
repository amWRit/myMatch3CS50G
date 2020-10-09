--[[
    GD50
    Match-3 Remake

    -- Board Class --

    Author: Colton Ogden
    cogden@cs50.harvard.edu

    The Board is our arrangement of Tiles with which we must try to find matching
    sets of three horizontally or vertically.
]]

Board = Class{}


function Board:init(x, y, level)
    self.x = x
    self.y = y
    self.level = level

    self.color_level = 12

    self.matches = {}

    self:initializeTiles()

    -- flag to store if there are possible matches in the board
    --self.matchesPossible = self:checkMatchesPossible()
end

function Board:initializeTiles()
    self.tiles = {}

    for tileY = 1, 8 do
        
        -- empty table that will serve as a new row
        table.insert(self.tiles, {})

        for tileX = 1, 8 do
            
            -- create a new tile at X,Y with a random color and variety
            -- at each increase in level, add a new variety of tile
            -- level 1 has only one variety, level 3 has 3 varieties of tile of same color
            -- after level 6, no new varieties remain though
            --  Tile:init(x, y, color, variety)
            table.insert(self.tiles[tileY], Tile(tileX, tileY, math.random(self.color_level), math.random(1, math.min(6, self.level))))
        end
    end

    while self:calculateMatches() do
        -- recursively initialize if matches were returned so we always have
        -- a matchless board on start
        self:initializeTiles()
    end

    -- if there are no possible matches in the board, keep resetting board until possibility is there
    while not self:checkMatchesPossible() do
        self:initializeTiles()
    end
end

--[[
    Goes left to right, top to bottom in the board, calculating matches by counting consecutive
    tiles of the same color. Doesn't need to check the last tile in every row or column if the 
    last two haven't been a match.
]]
function Board:calculateMatches()
    local matches = {}

    -- how many of the same color blocks in a row we've found
    local matchNum = 1

    -- horizontal matches first
    for y = 1, 8 do
        local colorToMatch = self.tiles[y][1].color
        local shinyFlag = self.tiles[y][1].shiny

        matchNum = 1
        
        -- every horizontal tile
        for x = 2, 8 do
            
            -- if this is the same color as the one we're trying to match...
            if self.tiles[y][x].color == colorToMatch then
                matchNum = matchNum + 1
                shinyFlag =  self.tiles[y][x].shiny or shinyFlag
            else
                -- set this as the new color we want to watch for
                colorToMatch = self.tiles[y][x].color

                -- if we have a match of 3 or more up to now, add it to our matches table
                if matchNum >= 3 then
                    local match = {}
                    local curr_x = 0
                    local back_pos = 0

                    if shinyFlag then 
                        curr_x = 8
                        back_pos = 1
                    else
                        curr_x = x - 1
                        back_pos =  x - matchNum     
                    end

                    -- go backwards from here by matchNum
                    for x2 = curr_x, back_pos, -1 do 
                        -- add each tile to the match that's in that match
                        table.insert(match, self.tiles[y][x2])
                    end
                    -- add this match to our total matches table
                    table.insert(matches, match)
                end

                matchNum = 1
                shinyFlag = self.tiles[y][x].shiny

                -- don't need to check last two if they won't be in a match
                if x >= 7 then
                    break
                end
            end
        end

        -- account for the last row ending with a match
        if matchNum >= 3 then
            local match = {}
            local back_pos = 0

            if shinyFlag then 
                back_pos = 1
            else
                back_pos =  8 - matchNum + 1    
            end

            -- go backwards from end of last row by matchNum
            for x = 8, back_pos , -1 do
                table.insert(match, self.tiles[y][x])
            end

            table.insert(matches, match)
        end

        --shinyFlag = false
    end

    -- vertical matches
    for x = 1, 8 do
        local colorToMatch = self.tiles[1][x].color
        local shinyFlag = self.tiles[1][x].shiny
        matchNum = 1

        -- every vertical tile
        for y = 2, 8 do
            if self.tiles[y][x].color == colorToMatch then
                matchNum = matchNum + 1
                shinyFlag =  self.tiles[y][x].shiny or shinyFlag
            else
                colorToMatch = self.tiles[y][x].color

                if matchNum >= 3 then
                    local match = {}
                    local curr_y = 0
                    local back_pos = 0

                    if shinyFlag then 
                        curr_y = 8
                        back_pos = 1
                    else
                        curr_y = y - 1
                        back_pos = y - matchNum
                    end

                    for y2 = curr_y, back_pos, -1 do
                        table.insert(match, self.tiles[y2][x])
                    end

                    table.insert(matches, match)
                end

                matchNum = 1
                shinyFlag = self.tiles[y][x].shiny

                -- don't need to check last two if they won't be in a match
                if y >= 7 then
                    break
                end
            end
        end

        -- account for the last column ending with a match
        if matchNum >= 3 then
            local match = {}
            local back_pos = 0
            
            if shinyFlag then 
                back_pos = 1
            else
                back_pos =  8 - matchNum + 1    
            end

            -- go backwards from end of last row by matchNum
            for y = 8, back_pos, -1 do
                table.insert(match, self.tiles[y][x])
            end

            table.insert(matches, match)
        end

    end

    -- store matches for later reference
    self.matches = matches

    -- return matches table if > 0, else just return false
    return #self.matches > 0 and self.matches or false
end

--[[
    Remove the matches from the Board by just setting the Tile slots within
    them to nil, then setting self.matches to nil.
]]
function Board:removeMatches()
    for k, match in pairs(self.matches) do
        for k, tile in pairs(match) do
            self.tiles[tile.gridY][tile.gridX] = nil
        end
    end

    self.matches = nil
end

--[[
    Shifts down all of the tiles that now have spaces below them, then returns a table that
    contains tweening information for these new tiles.
]]
function Board:getFallingTiles()
    -- tween table, with tiles as keys and their x and y as the to values
    local tweens = {}

    -- for each column, go up tile by tile till we hit a space
    for x = 1, 8 do
        local space = false
        local spaceY = 0

        local y = 8
        while y >= 1 do
            
            -- if our last tile was a space...
            local tile = self.tiles[y][x]
            
            if space then
                
                -- if the current tile is *not* a space, bring this down to the lowest space
                if tile then
                    
                    -- put the tile in the correct spot in the board and fix its grid positions
                    self.tiles[spaceY][x] = tile
                    tile.gridY = spaceY

                    -- set its prior position to nil
                    self.tiles[y][x] = nil

                    -- tween the Y position to 32 x its grid position
                    tweens[tile] = {
                        y = (tile.gridY - 1) * 32
                    }

                    -- set Y to spaceY so we start back from here again
                    space = false
                    y = spaceY

                    -- set this back to 0 so we know we don't have an active space
                    spaceY = 0
                end
            elseif tile == nil then
                space = true
                
                -- if we haven't assigned a space yet, set this to it
                if spaceY == 0 then
                    spaceY = y
                end
            end

            y = y - 1
        end
    end

    -- create replacement tiles at the top of the screen
    for x = 1, 8 do
        for y = 8, 1, -1 do
            local tile = self.tiles[y][x]

            -- if the tile is nil, we need to add a new one
            if not tile then

                -- new tile with random color and variety
                local tile = Tile(x, y, math.random(self.color_level), math.random(1, math.min(6, self.level)))
                tile.y = -32
                self.tiles[y][x] = tile

                -- create a new tween to return for this tile to fall down
                tweens[tile] = {
                    y = (tile.gridY - 1) * 32
                }
            end
        end
    end

    return tweens
end

function Board:render()
    for y = 1, #self.tiles do
        for x = 1, #self.tiles[1] do
            self.tiles[y][x]:render(self.x, self.y)
        end
    end
end

-- function to check if there are any possible matches in the board
-- it swaps each tile in all possible four directions and checks if there could be any matches. 
-- if only one match is seen as possible, it returns true without checking other remaining tiles
function Board:checkMatchesPossible()

    matchesPossible = false
    local directions = {'right', 'left', 'up', 'down'}

    -- for each column, go down tile by tile till the end
     for x = 1, 8 do

        local y = 1
        while y <= 8 do

            local selected_tile = self.tiles[y][x]
            local adjacent_tile = {}
            
            for i = 1, 4  do
                adjacent_tile = self:getAdjacentTile(directions[i], selected_tile)
                
                if not is_empty(adjacent_tile) then 

                    -- swap temporarily to test match
                    self:swapTiles(selected_tile, adjacent_tile)

                    -- was there any matches happened after swapping?
                    if self:calculateMatches() then 
                        matchesPossible = true
                        -- revert to original position
                        self:swapTiles(selected_tile, adjacent_tile)
                        hint =  'SWAP ' .. selected_tile.gridX .. '-' .. selected_tile.gridY .. 
                            ' ' .. tostring(directions[i])
                        -- since there are possible matches, no need to check for other moves
                        goto continue
                    else
                        -- revert to original position
                        self:swapTiles(selected_tile, adjacent_tile)
                    end
 
                end
            end
 
            y = y + 1 -- go to next tile in the column
        end
    end
    ::continue::

    return matchesPossible
end

-- function to get an adjacent tile of the tile passed in params; based on direction
function Board:getAdjacentTile(direction, selected_tile)
    local adjacent_tile = {}

    if direction == 'right' and selected_tile.gridX <= 7  then 

        adjacent_tile = self.tiles[selected_tile.gridY][selected_tile.gridX + 1]
    elseif direction == 'left' and selected_tile.gridX >= 2  then
        adjacent_tile = self.tiles[selected_tile.gridY][selected_tile.gridX - 1]
        
    elseif direction == 'up' and selected_tile.gridY >= 2 then
        adjacent_tile = self.tiles[selected_tile.gridY - 1][selected_tile.gridX]
        
    elseif direction == 'down' and selected_tile.gridY <= 7  then
        adjacent_tile = self.tiles[selected_tile.gridY + 1][selected_tile.gridX]
        
    end

    return adjacent_tile
end

function Board:swapTiles(selected_tile, adjacent_tile)
    -- swap grid positions of tiles
    local tempX = selected_tile.gridX
    local tempY = selected_tile.gridY

    selected_tile.gridX = adjacent_tile.gridX
    selected_tile.gridY = adjacent_tile.gridY
    adjacent_tile.gridX = tempX
    adjacent_tile.gridY = tempY

    -- swap tiles in the tiles table
    self.tiles[selected_tile.gridY][selected_tile.gridX] = selected_tile
    self.tiles[adjacent_tile.gridY][adjacent_tile.gridX] = adjacent_tile

    return selected_tile, adjacent_tile
end