# amWRit
=======
# Match3CS50G

__Assignment 3: "Match-3, The Shiny Update"__

__LOVE 11.3__

# Assignment Updates

__Time Addition__
- Scoring a match extends the timer by 1 second per tile.

__Tiles Based on Levels__
- Start with simple flat tiles.
- With increasing levels, more colored and patterned tiles are seen.
- Pattern tiles are worth more points.

__Shiny Tiles__
- Randomly spawn _shiny_ versions of tiles (random number and position).
- Shiny tiles will destroy an entire row on match, granting points for each block in the row.

__Can swap only if results in a Match__
- While trying to swap the tiles, if it doesn't result in a match, revert the swap. 
- Also render the revert of tiles.

__Reset Board__
- If there are no possibilities of matches remaining, reset the board. 

__Play with Mouse__ _(Optional)_
- Click on a tile (left click) to highlight a tile. Click on the other tile that you want to swap with.

__Hint__ _(Bonus)_
- Show hint, which tile to swap in which direction. 
- This was done just to make testing easier- to be removed if not needed.
=======
Assets included here were copied from the distrubuted source files by CS50. Codes were written with help from the course itself.0
