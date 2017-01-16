module network_input_display;

/*
Copyright (c) 2016, Logan Freesh
All rights reserved.

See "License.txt"
*/



import std.conv;
import std.stdio;


import unit;
import spaceships;


import dsfml.system;
import dsfml.graphics;


//static Color[] grey_table




class NetworkInputDisplay : Drawable
{
	static const float DISPLAY_SIZE =  5.0;
	static const float SPACING      =  3.0;
	static const float MAX_WIDTH    = 12.0;

	RectangleShape[][] _cells;
	
	Vector2f _base_position;
	Color    _base_color;
	
	Color[128] _shade_table;
	
	Vertex[][] _lines;
	
	
	this(Vector2f in_position, Color in_base_color)
	{
		_base_position = in_position;
		_base_color    = in_base_color;
	
		for(int i = 0 ; i < _shade_table.length; ++i)
		{
			double shade = i * 2; 
			ubyte r = to!ubyte( shade / 255.0f * _base_color.r );
			ubyte g = to!ubyte( shade / 255.0f * _base_color.g );
			ubyte b = to!ubyte( shade / 255.0f * _base_color.b );
			_shade_table[i] = Color(r, g, b);
		}
		
		//categories are:
		//unit counts at points
		//point controlled by
		//overall game state
		//distance to point
		//unit type
		//health and location boredom timer
		//unit lost and built counts
		//total costs at point	
		
		/////////////////////
		// Init row lengths
		/////////////////////
		int[] num_rows_in_categories = [ 0, 4*NUM_CAPTURE_POINTS, 2, 1, 2, 1, 1, 4, 2 ];
		int[] num_elements_for_rows_in_category = [NUM_UNIT_TYPES, NUM_CAPTURE_POINTS, 5, NUM_CAPTURE_POINTS, NUM_UNIT_TYPES, 2, NUM_UNIT_TYPES, NUM_CAPTURE_POINTS];
		
		int sum = 0;
		foreach( num_rows; num_elements_for_rows_in_category)
		{
			sum += num_rows;
		}
		_cells.length = sum;
		
		int start = 0;
		int end   = 0;
		for( int category_iter = 0 ; category_iter < num_elements_for_rows_in_category.length ; ++category_iter )
		{
			start += num_rows_in_categories[ category_iter ];
			end    = start + num_rows_in_categories[category_iter + 1];
			foreach ( row; start..end )
			{
				int num_elements   = num_elements_for_rows_in_category[category_iter];
				_cells[row].length = num_elements;
			}
		}
		
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
		//  2 rows: who controls which points
		//  1 row : incomes, game timer, ticket, enemy tickets
		//  2 rows: distance to each point, closest point
		//  1 row : unit type
        //  1 row : current health and "boredom timer"
		//  4 rows: unit lost counts, enemy unit lost counts, unit built counts, enemy unit built counts
		//  2 rows: total unit cost at point and enemy total unit cost at point
		int[] num_rows_between_lines = [NUM_CAPTURE_POINTS, NUM_CAPTURE_POINTS, NUM_CAPTURE_POINTS, NUM_CAPTURE_POINTS, 2, 1, 2, 1, 1, 4, 2 ];
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
				//assert(index <= 127 && index >= 0, "shade out of range: " ~ to!string(index) ~ " at row: " ~ to!string(row_count) ~ " col: " ~ to!string(col_count) );
				if(index < 0)
				{
					cell.fillColor = _shade_table[ 0 ];
					cell.outlineColor = Color.Red;
					cell.outlineThickness = 1.0f;
				} else
				if( index > 127)
				{
					cell.fillColor = _shade_table[ $-1 ];
					cell.outlineColor = Color.White;
					cell.outlineThickness = 1.0f;
				} else
				{
					cell.fillColor = _shade_table[ index ];
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


}