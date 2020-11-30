module collision;

/*
Copyright (c) 2016, Logan Freesh
All rights reserved.

See "License.txt"
*/



import steering;
import unit;
import spaceships;
import mathutil;

import std.conv;
import std.stdio; // debug prints

class CollisionGrid
{
	Vector2d _grid_start;
	Vector2d _grid_area;

	Vector2d _square_size;
	
	int _num_squares_wide;
	int _num_squares_tall;
	
	GridSquare[][] grid;
	
	
	this( Vector2d upper_right_corner, Vector2d area, int in_squares_wide, int in_squares_tall )
	{
		_grid_start = upper_right_corner;
		_grid_area  = area;

		_num_squares_wide = in_squares_wide;
		_num_squares_tall = in_squares_tall;
		
		grid.length = in_squares_wide;
		for( int i = 0 ; i < grid.length; ++i)
		{
			grid[i].length = in_squares_tall;
			for(int j = 0; j < grid[i].length; j++)
			{
				grid[i][j] = new GridSquare();
			}
		}
		
		_square_size = Vector2d( area.x / in_squares_wide , area.y / in_squares_tall );
		
	}
	
	
	void collision_query(Vector2d position, double radius, scope void delegate(Unit) process )
	{
	
		double radius_sq = square(radius);
		
		collision_query_grid_only (
			position, 
			radius,
			 delegate void(Unit u)
			{
				double dist_sq = square(position.x - u._pos.x) + square(position.y - u._pos.y);
				if( dist_sq < radius_sq)
				{
					process(u);
				}
			}
		);
	}
	
	
	void collision_query_grid_only( Vector2d position, double radius, scope void delegate(Unit) process )
	{
	
		//writefln("postition x is %f, radius is %f", position.x,radius);
		int min_grid_x = to_grid_x(position.x - radius);
		int max_grid_x = to_grid_x(position.x + radius);
		
		int min_grid_y = to_grid_y(position.y - radius);
		int max_grid_y = to_grid_y(position.y + radius);
		
		for(int iter_x = min_grid_x; iter_x <= max_grid_x; ++iter_x)
		{
			for(int iter_y = min_grid_y;  iter_y <= max_grid_y; ++iter_y)
			{
				foreach( unit ; grid[iter_x][iter_y]._units )
				{
					process(unit);
				}
			}
		}
	}
	
	
	//Unit query_find_unit()
	//{
	//	
	//}
	
	
	int to_grid_x(double pos_x)
	{
		int retval = to!int( (pos_x - _grid_start.x ) / _square_size.x );
		
		if( retval <  0                ) retval = 0;
		if( retval >= _num_squares_wide ) retval = _num_squares_wide - 1;
		
		return retval;
		
	}
	
	int to_grid_y(double pos_y)
	{
		int retval = to!int( (pos_y - _grid_start.y ) / _square_size.y );
		
		if( retval <  0                ) retval = 0;
		if( retval >= _num_squares_tall ) retval = _num_squares_tall - 1;
		
		return retval;
	}
	
	
	void update( Unit[] units )
	{
		foreach(row; grid)
		{
			foreach(square; row)
			{
				square._units.length = 0;
			}
		}
		
		foreach( unit ; units)
		{
			int grid_x = to_grid_x(unit._pos.x);
			int grid_y = to_grid_y(unit._pos.y);
			grid [grid_x][grid_y]._units ~= unit;
		}
	}
	
}


class GridSquare
{
	Unit[] _units;
}



/// nuthin' here yet






/+interface collider()
{
	float get_radius();
	Vector2f get_position();
	
	//col_observer*[] observers;
	
	//this(float in_radius)
	//{
	//	radius = in_radius;
	//}
	// needs some way to inform things about collisions, observer pattern? is that overthinking it?
}+/

//Steeringcollider
//rigidcollider