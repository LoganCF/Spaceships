WIP

This is simulation where Neural Networks play a Real-Time Strategy game against each other.

-------------------------------------------------------------------------------------
How to Build:
You will need the DMD compiler, available from: https://dlang.org/download.html#dmd
and DSFML from: http://jebbs.github.io/DSFML/downloads.html

This project includes the source for Artifical Neural networks in D (AND), a neural net library which I updated to be compatible with D2.0
The original source is available here: http://dsource.org/projects/and

Put the DSFML folder in the Spaceships/ folder.
Copy the DLLs from the DSFML/lib folder into the Spaceships/ folder.
Change the %dmd% variable in build.bat to reflect the location where you downloaded DMD.


The game:
Each player starts with a Mothership (large diamond) at opposing corners of the screen.
There are 12 capture points (+ symbols) on the screen.  Players gain an Income based on the number of Points they control, which determines how fast the Mothership can build new units.
Controlling more points than the opponent makes thier victory counter (bar at the top of the screen) shrink. 
A player wins by reducing thier opponent's victory counter to 0.

There are 11 types of ships in the game:
  Combat Ships:
    3 types of Fighters      (small): Fighers move quickly but have a short attack range.
    3 types of Light Ships  (medium):  Light ships are between Fighters and Capital ships in speed and range.
    3 types of Capital Ships (large): Capital Ships move slowly but can attack at long range.
    The shape of a combat ship indicates what size of ship it is effective against.
     Triangles deal double damage against Fighters.
     Circles deal double damage against Light Ships.
     Squares deal double damage agianst Capital Ships.
  Economic Ships:
    Mothership (large diamond): Builds units.  Multiple Motherships increase the overall speed of unit produciton.
    Miners     (small diamond): Increases the income when close to a point.  Multiple miners on the same point get diminishing returns.
    Economic ships are generally ineffective in combat, but deal equal damage to all targets.
      Mohterships have a lot of health, and moderate attack range.  They have Capital Ship armor (vulnerable to Squares)
      Miners have Light Ship armor (vulnerable to Circles)
