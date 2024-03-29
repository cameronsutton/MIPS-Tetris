![image](https://github.com/cameronsutton/MIPS-Tetris/assets/165424172/e53e553f-2b6c-49bf-9d9b-b7fb66ed5411)

# What This Is
This program is a reimplementation of the classic game Tetris. There are fully randomized pieces, guaranteed to be different each time because the Pseudo-RNG is seeded with the current system time. The pieces speed up as your score increases, meaning the difficulty increases as time goes on. Your score is based on the total number of lines you clear. If you clear 1, 2, 3, or 4 lines you get 1, 2, 4, or 8 points, respectively. 
The game board is 20 tall, 10 wide, and sports all 7 tetrominoes. The pieces fall, rotate, and spawn based on the [Super Rotation System](https://tetris.fandom.com/wiki/SRS) (SRS), the official guideline for how all Tetris pieces should behave. If any piece lands in the 21st row, a game over occurs and the game ends. 

# How To Play
1. Download MARS [here](https://courses.missouristate.edu/KenVollmar/mars/MARS_4_5_Aug2014/Mars4_5.jar)
2. Launch MARS and open `tetris.asm`
3. Under the "Tools" tab, select "Bitmap Display"
     * Set both unit width and height to 16
     * Set the display width to 256
     * Set the display height to 512
     * Change the base address for display to `$gp`
     * Change the resolution of the bitmap display window to ensure the entire display fits on your screen
     * Select "Connect to MIPS" in the bottom left corner

4. Under the "Tools" tab, select "Keyboard and Display MMIO Simulator"
     * Select "Connect to MIPS" in the bottom left corner
     * To play the game, send key inputs into the bottom box of the Keyboard and Display window
5. Select the "Assemble" button near the top, its icon is a wrench and screwdriver
6. Select the now available "Run" button next to the Assemble button

## Controls
- Move piece left: a
- Move piece right: d
- Move piece down: s
- Rotate Piece - r
- Exit game - space (only in game over screen)

# Game Loop:
1.	Initialize the program:
    1.	Initialize RNG seed, starting piece fall rate, and number offsets.
    2.	Draw “score”, and the score numbers
2.	Game loop:
    1.	Check if a piece needs to be spawned, if it does, spawn it.
    2.	Check if the piece needs to be lowered by 1
         1.	If space below piece is free, lower it
         2.	Else: Freeze piece in place
    3.	If piece was frozen:
         1.	If piece landed above board, go to game over
         2.	If a row is complete, remove it and shift down pieces, update the score, and update the drop rate
    4.	Check for any player input:
         1.	If player entered “a”, shift piece left
         2.	Else if player entered “d”, shift piece right
         3.	Else if player entered “s”, shift piece down
         4.	Else if player entered “r”, rotate piece
    5.	Do nothing for 10 milliseconds, then increment main counter by 1
    6.	Go back to start of game loop.
3.	Game over:
    1.	Clear game-field of all pieces and borders
    2.	Draw game-over text
    3.	Wait for user to press spacebar to exit program


# Additional Notes

## Running Speed:
This program was created with speed in mind from the beginning. I have noticed MARS can be incredibly slow with bitmap-related programs, and the last thing I wanted was a slow, jittery game so I decided to not risk having to rewrite things. To increase speed, I decided to not use any general-purpose pixel drawing function, and to not use a cartesian coordinate system.

I instead based everything on its offset from the global pointer, or in other words how many pixels away it is from the first pixel. By doing this, I could use MIPS’s built-in memory-offset indexing system for accessing data, which removed any position conversion calculations in between load/store operations.

Lag can still be seen in certain spots in the game. The most apparently places are during game launch, when clearing lines, and on game overs. Game launch and game over aren’t that big of a deal, but for clearing lines I added code to only execute a loop for the minimum necessary cycles, although clearing lines on a filled board will still cause a noticeable delay.

## Piece Movement and Rotation

The piece rotation function is by far the longest function in this project, being ~800 lines out of the ~2500 lines of (uncompiled) code. The reason for this is because Tetris pieces have a wall-kicking system, where it will try to fit into 5 different locations on a rotation instead of just 1. The most obvious display of this is rotating a line-piece while directly next to a wall. Instead of getting lodged in the wall, it will be kicked away by some amount. Implementing all 5 checks for all 4 of rotations of all 7 of the pieces resulted in a lot of code.

Looking back at the code, I realize I could have implemented my macros in a smarter way, but I think that better use of macros will cut out at most 50% of the code currently in the function. The macros would not change the length of the compiled code for this function (which is 2,488 instructions) by any notable amount, but it would have made development a little easier. Cutting out more code would require overhauling my implementation.

Side note, this project has given me a new-found respect for the square piece.

## Piece Drop Rate

| Score   | Delay (seconds) |
|---------|-----------------|
| 0-9     | 0.5             |
| 10-19   | 0.45            |
| 20-29   | 0.4             |
| 30-39   | 0.35            |
| 40-49   | 0.3             |
| 50-74   | 0.25            |
| 75-99   | 0.2             |
| 100-149 | 0.15            |
| 150+    | 0.1             |

## Programming Tidbits:
There are 2 labels at the very end of the file called “generic_function_return” and “generic_function_return_stack_pop”. The first one only has a “jr $ra” instruction in it, and the second one pops $ra off the stack, and then executes “jr $ra”. These make it convenient for any branch-comparison instructions where the branch should make the function return. Rather than having to make a label at the end of every function for returning, I could just use these generic return labels.

The source code for this project is 2365 lines long, but the compiled code is 4802 lines due to the extensive use of macros.

The game runs at a theoretical frame rate of 100 fps, but the actual number is much lower since this assumes the game logic is instant.

The game has 8 global variables for keeping track of the following things
1. A main counter for timing when pieces should drop
2. Tracks the currently falling piece with a number 0-6 (inclusive)
3. The rotation of the currently falling piece
4. The $gp offset of the currently falling piece
5. The score
6. The drop rate for tracking how often pieces should drop
7. The game state flag. 0 is playing, 1 is game over.
8. Falling flag. If a piece is falling, the flag is 1, otherwise it is 0.
	
 No special wall-collision code was needed since the piece collision code does not distinguish walls from pieces.

 ## Sprites
The following are the letter and number sprites the game uses.

![image](https://github.com/cameronsutton/MIPS-Tetris/assets/165424172/7bac8b7b-183f-4290-b608-03d1aaa8742c)



