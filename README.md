
This is simulation where Neural Networks play a Real-Time Strategy game against each other.

You can see a video of it in action here: https://youtu.be/2T_Yk-HM9xg

#How to Build:
You will need the DMD compiler, available from: https://dlang.org/download.html#dmd
and DSFML from: http://jebbs.github.io/DSFML/downloads.html

This project includes the source for Artifical Neural networks in D (AND), a neural net library which I updated to be compatible with D2.0
The original source is available here: http://dsource.org/projects/and

Put the DSFML folder in the Spaceships/ folder.
Copy the DLLs from the DSFML/lib folder into the Spaceships/ folder.
Change the %dmd% variable in build.bat to reflect the location where you downloaded DMD.



#The Game:
Each player starts with a Mothership (large diamond) at opposing corners of the screen.
There are 12 capture points (+ symbols) on the screen.  Players gain an Income based on the number of Points they control, which determines how fast the Mothership can build new units.
Controlling more points than the opponent makes thier victory counter (bar at the top of the screen) shrink. 
A player wins by reducing thier opponent's victory counter to 0.

There are 6 types of ships in the game:
  Combat Ships:
    2 types of Small Ships: Small Ships are fast and deal high damage for thier cost.
      Interceptor (small triangle)
      Destroyer   (small sqaure)  
    2 types of Large Ships: Large Ships are slow and costly to produce, but have a significantly longer attack range.
      Cruiser     (large triangle)
      Battleship  (large square)
    The shape of a combat ship indicates what size of ship it is effective against.
     Triangles deal double damage against Small Ships.
     Squares deal double damage against Large Ships.
  Economic Ships:
    Mothership (large diamond): Builds units.  Multiple Motherships increase the overall speed of unit produciton.
    Miner      (small diamond): Increases the income when close to a point.  Multiple miners on the same point get diminishing returns.
    Economic ships are ineffective in combat, but deal equal damage to all targets.
      Mohterships have a lot of health, and moderate attack range.  They have Large Ship armor (vulnerable to squares)
      Miners have Small Ship armor (vulnerable to triangles)

##Observer Controls:
  When watching the AI's play against each other, you can press Alt + End to start the next match if the current one is uninteresting (as many will be if the NN's haven't been training for very long)
  

##Manual Controls:
By running play_spaceships.bat, you can manually control a fleet against the Neural Net AIs.
  in this mode, press the Q, W, E, A, S, D keys to change the type of unit currently being produced.
  These keys form a grid based on the properties of the unit type:
    The first row  (Q, W, E) produce Small Ships
    The second row (A, S, D) produce Large Ships
    
    The first column  (Q, A) produces units which are effective against Small Ships.
    The second column (W, S) produces units which are effective against Large Ships.
    The third column  (E, D) produces economic units.
    
  To control your units:
    Right-Click to instruct any currently selected units to move to the location of your mouse pointer.
  
    Left-Click and drag to select all units in a circle. (this will be chagned to a square after an update to the collision-detection system)
    Press Space to select all non-economic units near your cursor.
    Hold shift while selecting to add units to your current selection.
