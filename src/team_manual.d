module team_manual;


/*
Copyright (c) 2016, Logan Freesh
All rights reserved.

See "License.txt"
*/



import std.stdio;

import team;
import steering;
import collision;
import unit;
import factory_unit;

import dsfml.graphics;
import dsfml.system;


class PlayerTeam : TeamObj
{
	Unit[] _selected;
	
	RenderWindow _window; // kludge, input should be polled elsewhere.
	
	bool     _selecting;
	Vector2d _selection_start;
	
	CircleShape _selection_circle;
	Vector2d _selection_circle_center;
	double _selection_circle_diameter;
	
	bool _right_click_was_pressed_last_frame = false;
	
	string _player_name;
	
	this(TeamID in_id, inout Color in_color, inout char[] in_name, inout char[] in_player_name = cast(inout char[])"Player" ) 
	{
		super( in_id, in_color, in_name );
		
		_selection_circle = new CircleShape();
		_selection_circle.outlineThickness = 1.0f;
		_selection_circle.outlineColor     = Color.White;
		_selection_circle.fillColor        = Color.Transparent;
	}
	
	
	
	
	override int assign_command(Unit unit)
	{
		return unit._destination_id;
	}
	
	override UnitType get_build_order ( FactoryUnit building_unit )
	{
		return UnitType.Interceptor;
	}
	
	override void update( CollisionGrid grid, double dt )
	{
		
		// left-click selection
		if(!_selecting)
		{
			if( Mouse.isButtonPressed(Mouse.Button.Left) )
			{
				_selecting = true;
				
				Vector2i mouse_pos = Mouse.getPosition(_window);
				_selection_start  = Vector2d( mouse_pos.x, mouse_pos.y );
			}
		} else {
			if( Mouse.isButtonPressed(Mouse.Button.Left) )
			{
				Vector2i mouse_pos = Mouse.getPosition(_window);
				Vector2d selection_end  = Vector2d( mouse_pos.x, mouse_pos.y );
				
				//find circle size and center
				_selection_circle_center = (_selection_start + selection_end) / 2;
				
				_selection_circle_diameter = sqrt( square(_selection_start.x - selection_end.x) + square(_selection_start.y - selection_end.y) );
				
			} else {
				_selecting = false;
				
				if( ! (Keyboard.isKeyPressed(Keyboard.Key.LShift) || Keyboard.isKeyPressed(Keyboard.Key.RShift) ) )
				{
					foreach( unit; _selected )
					{
						unit._disp.outlineThickness = 0.0f;
					}
					_selected.length = 0;
				}
				
				grid.collision_query
				( 
					_selection_circle_center, _selection_circle_diameter / 2,
					delegate void(Unit u)
					{
						_selected ~= u;
						u._disp.outlineColor = Color.White;
						u._disp.outlineThickness = 1.0f;
					}
				);
			}
			
		} // done dealing with left-click selection
		
		//space to select
		if( Keyboard.isKeyPressed(Keyboard.Key.Space) )
		{
			Vector2i mouse_pos        = Mouse.getPosition(_window);
			Vector2d mouse_pos_double = Vector2d( mouse_pos.x, mouse_pos.y );
			
			if( ! (Keyboard.isKeyPressed(Keyboard.Key.LShift) || Keyboard.isKeyPressed(Keyboard.Key.RShift) ) )
			{
				foreach( unit; _selected )
				{
					unit._disp.outlineThickness = 0.0f;
				}
				_selected.length = 0;
			}
			
			grid.collision_query
			(
				mouse_pos_double, 150.0,
				delegate void(Unit u)
				{
					// if mine and not an econ ship, select
					if( u._team._id == _id && u._type != UnitType.Mothership && u._type != UnitType.Miner )
					{
						_selected ~= u;
						u._disp.outlineColor = Color.White;
						u._disp.outlineThickness = 1.0f;
					}
				}
			);
		}
		
		//right click to order move
		//TODO: mouse released event
		if( ! Mouse.isButtonPressed(Mouse.Button.Right)
			&& _right_click_was_pressed_last_frame       )
		{
			// give move orders and record it for the NNs
			Vector2i mouse_pos = Mouse.getPosition(_window);
			Vector2d move_to  = Vector2d( mouse_pos.x, mouse_pos.y );
		
			int    closest_point;
			double closest_dist_sq = 999999999.0;
			foreach(int index , point; _points)
			{
				double dist_sq = square(point._pos.x - move_to.x) + square(point._pos.y - move_to.y);
				if( dist_sq < closest_dist_sq )
				{
					closest_point = index;
					closest_dist_sq = dist_sq;
				}
			}
			
			foreach(unit ; _selected)
			{
				unit._destination = move_to;
				
				if(unit._destination_id != -1)
				{
					_unit_destination_counts[ unit._destination_id ][unit._type] --;
				}
				unit._destination_id = closest_point;
				_unit_destination_counts[closest_point         ][unit._type] ++;
				
				record_move_order(unit, closest_point);
				_num_orders_given++;
			}
		}	

		_right_click_was_pressed_last_frame = Mouse.isButtonPressed(Mouse.Button.Right);		
		
		//Event event;
		/+while(_window.pollEvent(event))
		{
			if (event.type == Event.EventType.KeyPressed)
			{+/
				UnitType build_command = get_unit_type_from_keypress(/+event.key.code+/);
				
				/*if(_selection.length != 0)
				{
					// TODO: only order selected factories.
				}*/
				
				if( build_command != UnitType.None )
				{
					foreach(factory ; *_factories)
					{
						if(factory._team._id == this._id)
						{
							factory.change_build( build_command );
							_num_builds ++;
						}
					}
				}
			//}
		//}
		
		super.update(grid, dt);
	}
	
	
	//increment num builds and num commands
	
	override void draw(RenderTarget renderTarget, RenderStates renderStates)
	{
		if(_selecting)
		{
			// draw selection circle
			_selection_circle.radius   = _selection_circle_diameter / 2;
			// compute diagonal offset for the radius
			Vector2f selection_circle_offset = Vector2f(_selection_circle.radius/ -SQRT2 , _selection_circle.radius / -SQRT2 );
			_selection_circle.position = cast(Vector2f)_selection_circle_center + selection_circle_offset;
			//_selection_circle.position = _selection_circle_position;
			
			renderTarget.draw( _selection_circle );
		}
	}
	
	void set_window(RenderWindow w)
	{
		_window = w;
	}
	
	
	
	override void handle_endgame(bool won_game)
	{
		_build_ai  .load_or_initialize_net();
		_command_ai.load_or_initialize_net();
		
		_game_over = true;
		if(won_game)
		{
			writefln("-----------%s Won!   %d orders, %d builds----------", _player_name , _num_orders_given, _num_builds);
			writeln("Training winner's build AI:");
			_build_ai.train_net(true);
			writeln("Training winner's command AI:");
			_command_ai.train_net(true);
			
			writeln("Training loser's build AI to emulate winner:");
			_opponent._build_ai.train_net_to_emulate(this._build_ai); 
			writeln("Training loser's command AI to emulate winner");
			_opponent._command_ai.train_net_to_emulate(this._command_ai);
		} else {
			writefln("-----------%s Lost!  %d orders, %d builds-----------", _player_name, _num_orders_given, _num_builds);
			writeln("Training loser's build AI:");
			_build_ai.train_net(false);
			writeln("Training loser's command AI:");
			_command_ai.train_net(false);
		}
		
		_build_ai  .save_net();
		_command_ai.save_net();
		
		// TODO: reset game state (from main?).
	}
}



UnitType get_unit_type_from_keypress(/+Keyboard.Key pressed+/ )
{
	/+switch( pressed )
	{
		with( Keyboard.Key )
		{
			case Q:
				return UnitType.Interceptor;
			case W:
				return UnitType.AssaultFighter;
			case E:
				return UnitType.Bomber;
				
			case A:
				return UnitType.Corvette;
			case S:
				return UnitType.Frigate;
			case D:
				return UnitType.Destroyer;
			case F:
				return UnitType.Miner;
				
			case Z:
				return UnitType.Cruiser;
			case X:
				return UnitType.BattleCruiser;
			case C:
				return UnitType.Battleship;
			case V:
				return UnitType.Mothership;
				
			default:
				break;
		}
	}+/
	
	with( Keyboard.Key )
	{
		if( Keyboard.isKeyPressed( Q ) )
			return UnitType.Interceptor;
		if( Keyboard.isKeyPressed( W ) )
			return UnitType.AssaultFighter;
		if( Keyboard.isKeyPressed( E ) )
			return UnitType.Bomber;
			
		if( Keyboard.isKeyPressed( A ) )
			return UnitType.Corvette;
		if( Keyboard.isKeyPressed( S ) )
			return UnitType.Frigate;
		if( Keyboard.isKeyPressed( D ) )
			return UnitType.Destroyer;
		if( Keyboard.isKeyPressed( F ) )
			return UnitType.Miner;
			
		if( Keyboard.isKeyPressed( Z ) )
			return UnitType.Cruiser;
		if( Keyboard.isKeyPressed( X ) )
			return UnitType.BattleCruiser;
		if( Keyboard.isKeyPressed( C ) )
			return UnitType.Battleship;
		if( Keyboard.isKeyPressed( V ) )
			return UnitType.Mothership;
			
	}
	
	return UnitType.None;
}

