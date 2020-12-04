module network_input_display;

/*
Copyright (c) 2016, Logan Freesh
All rights reserved.

See "License.txt"
*/



import std.conv;
import std.stdio;
import std.math;
import std.algorithm.comparison;

import unit;
import spaceships;


import dsfml.system;
import dsfml.graphics;


//static Color[] grey_table

const int NUM_SHADES = 128;


class NetworkInputDisplay : Drawable
{
	static const float DISPLAY_SIZE =  5.0;
	static const float SPACING      =  3.0;
	static const float MAX_WIDTH    = 12.0;

	RectangleShape[][] _cells;
	
	Vector2f _base_position;
	Color    _base_color;
	Color    _alternate_base_color;
	
	Color[NUM_SHADES] _shade_table;
	Color[NUM_SHADES] _alternate_shade_table;
	bool[] _use_alternate_shade;
	
	Vertex[][] _lines;
	
	
	this(Vector2f in_position, Color in_base_color, Color in_alternate_base_color)
	{
		_base_position = in_position;
		_base_color    = in_base_color;
		_alternate_base_color = in_alternate_base_color;
	
		for(int i = 0 ; i < _shade_table.length; ++i)
		{
			double shade = i * 2; 
			ubyte r = to!ubyte( shade / 255.0f * _base_color.r );
			ubyte g = to!ubyte( shade / 255.0f * _base_color.g );
			ubyte b = to!ubyte( shade / 255.0f * _base_color.b );
			_shade_table[i] = Color(r, g, b);
		}
		
		for(int i = 0 ; i < _shade_table.length; ++i)
		{
			double shade = i * 2; 
			ubyte r = to!ubyte( shade / 255.0f * _alternate_base_color.r );
			ubyte g = to!ubyte( shade / 255.0f * _alternate_base_color.g );
			ubyte b = to!ubyte( shade / 255.0f * _alternate_base_color.b );
			_alternate_shade_table[i] = Color(r, g, b);
		}
		
		
		//categories are:
		//unit counts at points (at each point and by type)
		//unit counts by type
		//total costs at point	
		//threat at point
		//point controlled by
		//team status / overall game state
		//distance to point and closest point
		//unit type
		//health, unit status and stats
		//unit lost and built counts
		
		
		/////////////////////
		// Init row lengths
		/////////////////////
		int[] num_rows_in_categories = [ 4*NUM_CAPTURE_POINTS, 2, 2, 1, 2, 1, 2, 1, 1, 4];
		int[] num_elements_for_rows_in_category = [NUM_UNIT_TYPES, NUM_UNIT_TYPES, NUM_CAPTURE_POINTS, NUM_CAPTURE_POINTS, NUM_CAPTURE_POINTS, 8, NUM_CAPTURE_POINTS, NUM_UNIT_TYPES, 9, NUM_UNIT_TYPES];
		
		//init array of rows
		int total_elements = 0;
		int sum = 0;
		foreach( num_rows; num_rows_in_categories)
		{
			sum += num_rows;
		}
		_cells.length = sum;
		
		//now init the rows themselves
		int start = 0;
		int end   = 0;
		for( int category_iter = 0 ; category_iter < num_elements_for_rows_in_category.length ; ++category_iter )
		{
			end    = start + num_rows_in_categories[category_iter];
			foreach ( row; start..end )
			{
				int num_elements   = num_elements_for_rows_in_category[category_iter];
				_cells[row].length = num_elements;
				total_elements += num_elements;
			}
			start += num_rows_in_categories[ category_iter ];
		}

		
		///////////////////////////////////
		// Mark which use alternate shade
		///////////////////////////////////
		
		_use_alternate_shade.length = total_elements;
		_use_alternate_shade[] = false;
		
		
		int base_index = 0;
		void mark(int start, int len)
		{
			_use_alternate_shade[base_index + start .. base_index + start + len] = true;
			base_index += start + len;
		}
		
		// TODO: the data really needs to be structured in some way
		mark(2*NUM_CAPTURE_POINTS*NUM_UNIT_TYPES, 2*NUM_CAPTURE_POINTS*NUM_UNIT_TYPES); // opponent unit locations and destinations
		
		mark(NUM_UNIT_TYPES, NUM_UNIT_TYPES); // opp. total units by type
		mark(NUM_CAPTURE_POINTS,NUM_CAPTURE_POINTS); // total cost at point
		mark(NUM_CAPTURE_POINTS, NUM_CAPTURE_POINTS); // is point enemy
		mark(NUM_CAPTURE_POINTS+1,1); // income
		mark(1,1); //total army value
		mark(3,1); // tickets
		mark(NUM_CAPTURE_POINTS*2+NUM_UNIT_TYPES+9+NUM_UNIT_TYPES*2, NUM_UNIT_TYPES*2); // units built/lost counts, skipping unit stats and type
		
		
		
		///////////////////////////
		// Init cells in each row
		///////////////////////////
		
		foreach( row_count, row; _cells )
		{
			foreach( col_count, ref cell; row )
			{
				cell = new RectangleShape( Vector2f(DISPLAY_SIZE, DISPLAY_SIZE) );
				//cell.size       = Vector2f(DISPLAY_SIZE, DISPLAY_SIZE);
				Vector2f offset = Vector2f( (SPACING + DISPLAY_SIZE) * col_count,
											(SPACING + DISPLAY_SIZE) * row_count  );
				cell.position   = _base_position + offset;
			}
		}
		
		////////////////////////
		// Init dividing lines
		////////////////////////
		
		// they divide:
		// 12 rows: unit count at point (each row is a point)
		// 12 rows: unit destination_counts
		// 12 rows: enemy unit count at point
		// 12 rows: enemy unit destination_counts
		//  2 rows: units counts by type, opponent " " " "
		//  2 rows: total unit cost at point and enemy " " " " "
		//  1 row : threat diff at point
		//  2 rows: who controls which points
		//  1 row : team status / game state
		//  2 rows: distance to point, closest point
		//  1 row : unit type
        //  1 row : current health, "boredom timer", and stats
		//  4 rows: unit lost counts, enemy unit lost counts, unit built counts, enemy unit built counts
		
		int[] num_rows_between_lines = [0, NUM_CAPTURE_POINTS, NUM_CAPTURE_POINTS, NUM_CAPTURE_POINTS, NUM_CAPTURE_POINTS, 2, 2, 1, 2, 1, 2, 1, 1, 4 ];
		int row_counter = 0;
		
		float line_width = (MAX_WIDTH - 1) * SPACING + MAX_WIDTH * DISPLAY_SIZE;
		
		foreach( num_rows; num_rows_between_lines )
		{
			row_counter += num_rows;
			float line_height = row_counter * DISPLAY_SIZE  +  (row_counter - 1) * SPACING  +  SPACING / 2;
			_lines ~= [
						Vertex( _base_position + Vector2f(0         , line_height), _base_color),
						Vertex( _base_position + Vector2f(line_width, line_height), _base_color)
						];
		}
		

		
	}
	
	
	void set_state( real[] inputs )
	{
		int input_iter = 0;
		foreach(row_count, row; _cells )
		{
			foreach(col_count, cell; row )
			{
				int index = to!int( inputs[input_iter] * ( _shade_table.length - 1 ) );
				Color[] table = _use_alternate_shade[input_iter] ? _alternate_shade_table : _shade_table;
				//assert(index <= 127 && index >= 0, "shade out of range: " ~ to!string(index) ~ " at row: " ~ to!string(row_count) ~ " col: " ~ to!string(col_count) );
				if(index < 0)
				{
					cell.fillColor = table[ min(abs(index),127) ];
					cell.outlineColor = Color.Red;
					cell.outlineThickness = 1.0f;
				} else
				if( index > 127)
				{
					cell.fillColor = table[ $-1 ];
					cell.outlineColor = Color.White;
					cell.outlineThickness = 1.0f;
				} else
				{
					cell.fillColor = table[ index ];
					cell.outlineThickness = 0.0f;
				}
				input_iter++;
			}
		}
	}
	
	
	void draw (RenderTarget renderTarget, RenderStates renderStates) 
	{
		foreach(row; _cells)
		{
			foreach(cell; row)
			{
				cell.draw( renderTarget, renderStates );
			}
		}
		
		foreach(line ; _lines)
		{
			renderTarget.draw( line, PrimitiveType.Lines, renderStates);
		}
	}
	
	Vector2f size()
	{
		float size_of_x_cells_with_spacing(inout int x)
		{
			return x * DISPLAY_SIZE + (x - 1) * SPACING;
		}
		return Vector2f(size_of_x_cells_with_spacing(to!(const int)(MAX_WIDTH)), size_of_x_cells_with_spacing(_cells.length));
	}


}