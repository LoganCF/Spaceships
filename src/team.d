module team;

/*
Copyright (c) 2016, Logan Freesh
All rights reserved.

See "License.txt"
*/


import std.random;
import std.algorithm.mutation;
import std.conv;
import std.stdio;

import spaceships;
import steering;
import collision;
import unit;
import factory_unit;
import capture_point;
import ai_base;
import ai_build;
import ai_command;
import network_input_display;
import matchinfo;

import dsfml.graphics;



enum TeamID {One, Two, Neutral}

const double INCOME_BASE = 20.0;
const double INCOME_PER_POINT = 20.0;

class TeamObj : Drawable
{
	double _income = 0.0;
	double _income_per_factory;
	double _tickets = g_starting_tickets;
	
	Color  _color;
	
	TeamID _id;
	char[] _name;
	
	TeamObj _opponent;
	
	FactoryUnit[]* _factories;
	CapturePoint[] _points; // list of all points.
	int[][]  _unit_counts;
	int[][]  _unit_destination_counts;
	double[] _unit_total_cost_at_points; // set by capture point objects
	int[]    _unit_built_counts;
	int[]    _unit_lost_counts;
	
	BuildAI   _build_ai;
	CommandAI _command_ai;
	
	int _num_factories = 0;
	int _num_orders_given = 0;
	int _num_builds     = 0;
	int _num_points_owned = 0;
	
	double _game_timer = 0.0;
	bool   _game_over = false;
	
	bool _draw_NN_inputs;
	NetworkInputDisplay _input_disp;
	
	MatchInfo _match_info;
	
	this(TeamID in_id, inout Color in_color, inout char[] in_name  ) // will take AI objects.
	{
		_build_ai   = new BuildAI(in_name ~ "_build.txt"); 
		_command_ai = new CommandAI(in_name ~ "_command.txt");
		_color = in_color;
		_id = in_id;
		_name = in_name.dup();
		
		_unit_built_counts.length = NUM_UNIT_TYPES;
		_unit_lost_counts.length  = NUM_UNIT_TYPES;
	}
	
	
	static const double MINER_INCOME_FRACTION = 0.25;
	
	void update(CollisionGrid grid, double dt)
	{
		_game_timer += dt;
		//reset unit counts
		foreach( count ; _unit_counts )
		{
			count.fill(0);
		}
		
		// this doesn't need to be reset each frame
		/*foreach ( dest_count; _unit_destination_counts )
		{
			dest_count.fill(0);
		} */
		
		_unit_total_cost_at_points.fill(0.0);
		
		_num_points_owned = 0;
		
		//deal with income
		_income = INCOME_BASE;
		foreach(point; _points)
		{
			if( point._team_id == _id )
			{
				_num_points_owned++;
			
				double income_from_this_point = INCOME_PER_POINT;
				//deal with Miner ships, each miner adds 1/4th the remaining distance between double the point's income
				for(int i = 0; i < _unit_counts[point._zone_number][UnitType.Miner]; ++i) 
				{
					income_from_this_point += (INCOME_PER_POINT * 2 - income_from_this_point) * MINER_INCOME_FRACTION; 
				}
				
				_income += income_from_this_point;
			}
		}
		
		_income_per_factory = _income /log2(_num_factories+1); // so Mothership spamming isn't overpowered
		
		
		//assert(_opponent !is null );
		
		if( _opponent !is null && _num_points_owned < _opponent._num_points_owned)
		{
			_tickets -= (_opponent._num_points_owned - _num_points_owned) * dt;
			if( _tickets <= 0.0 )
			{
				handle_endgame(false); //you lose!
				_opponent.handle_endgame(true); // opponent wins!
			}
		} 
		
		if(_opponent is null) writeln("Opponent is null.");
		
		
	}
	
	void draw(RenderTarget renderTarget, RenderStates renderStates)
	{
		//empty( not anymore! ), subclasses can use this to display additional data.
		
		
		if(_input_disp !is null )
		{
			_input_disp.draw(renderTarget, renderStates);
		}
			
			
		
	}
	
	void set_NN_input_display( NetworkInputDisplay in_disp )
	{
		_input_disp = in_disp;
	}
	
	void set_opponent(TeamObj in_opponent)
	{
		assert(in_opponent !is null);
		_opponent = in_opponent;
	}
	
	void set_points(CapturePoint[] in_points)
	{
		_points = in_points;
		//debug writefln("points has %d elements", _points.length);
		_unit_counts.length = _points.length;
		_unit_destination_counts.length = _points.length;
		_unit_total_cost_at_points.length = _points.length;
		_unit_total_cost_at_points.fill(0.0);
		
		for(size_t i=0; i < _unit_counts.length; ++i)
		{
			_unit_counts[i].length = NUM_UNIT_TYPES;
		}
		for(size_t i=0; i < _unit_destination_counts.length; ++i)
		{
			_unit_destination_counts[i].length = NUM_UNIT_TYPES;
		}
	}
	
	void set_factory_array( FactoryUnit[]* in_factories )
	{
		_factories = in_factories;
	}
	
	void set_match_info(MatchInfo info)
	{
		_match_info = info;
	}
	
	
	
	
	
	real[] get_common_ai_inputs(Unit unit)
	{
		real[] inputs = [ ];
		
		//TODO: calculate the board state for the team externally, the first time it is needed each frame, and cache that shit.
		add_num_units_scaled_by_cost_to_array( 		     _unit_counts	 		 , &inputs );
		add_num_units_scaled_by_cost_to_array( 		     _unit_destination_counts, &inputs );
		add_num_units_scaled_by_cost_to_array( _opponent._unit_counts  		     , &inputs );
		add_num_units_scaled_by_cost_to_array( _opponent._unit_destination_counts, &inputs );
		//writefln("input size after unit counts: %d, expected value: %d, unittype has %d", inputs.length, NUM_UNIT_TYPES * NUM_CAPTURE_POINTS * 4, NUM_UNIT_TYPES);
		
		foreach( point ; _points)
		{
			inputs ~= (point._team_id == _opponent._id ) ? 1.0 : 0.0;
		}
		foreach( point ; _points)
		{
			inputs ~= (point._team_id == TeamID.Neutral) ? 1.0 : 0.0;
		}
		
		inputs ~= _income           / _match_info._total_income_from_points;
		inputs ~= _opponent._income / _match_info._total_income_from_points;
		inputs ~= _game_timer / _match_info._timer_max;
		
		inputs ~= _tickets           / _match_info._tickets_max;  // g2.5
		inputs ~= _opponent._tickets / _match_info._tickets_max;  // g2.5
		
		foreach( point ; _points )
		{
			double dist = sqrt( square(unit._pos.x - point._pos.x) + square(unit._pos.y - point._pos.y) );
			inputs ~= dist / _match_info._battlefield_diagonal;
		}
		
		for( UnitType iter = UnitType.min; iter < UnitType.max; ++iter )
		{
			if(iter != UnitType.None)
			{
				inputs ~= (iter == unit._type) ? 1.0 : 0.0;
			}
		}
			
		inputs ~= unit._health_current / unit._health_max;
		
		// following are gen2 params
		
		// location boredom
		inputs ~= always_positive_to_01( sigmoid(unit._location_boredom_timer) );
		
		// num unit lost
		foreach( UnitType type, lost_count; _unit_lost_counts)
		{
			inputs ~= num_units_scaled_by_cost(lost_count, type);
		}
		// num unit killed
		foreach( UnitType type, lost_count; _opponent._unit_lost_counts)
		{
			inputs ~= num_units_scaled_by_cost(lost_count, type);
		}
		
		// num unit built
		foreach( UnitType type, built_count; _unit_built_counts)
		{
			inputs ~= num_units_scaled_by_cost(built_count, type);
		}
		// num enemy unit built
		foreach( UnitType type, built_count; _opponent._unit_built_counts)
		{
			inputs ~= num_units_scaled_by_cost(built_count, type);
		}
		
		// total unit cost at point
		foreach(total_cost; _unit_total_cost_at_points)
		{
			inputs ~= total_cost / UNIT_COST_SCALING_DIVISOR;
		}
		// enemy total cost at point
		foreach(total_cost; _opponent._unit_total_cost_at_points)
		{
			inputs ~= total_cost / UNIT_COST_SCALING_DIVISOR;
		}
		
		
		foreach (input; inputs)
		{
			assert(!isNaN(input), "garbage in!");
		}
		
		return inputs;
	
	
	}
	
	
	real[] get_command_inputs(Unit unit)
	{
		return get_common_ai_inputs(unit);
	}

	int assign_command(Unit unit)
	{
		_num_orders_given++;
		// TODO: use unit._type
		// TODO: compute distance to each point.
		
		assert(_opponent !is null);
		
		real[] inputs = get_command_inputs(unit);
		
		if( _input_disp !is null && unit._type == UnitType.Mothership )
		{
			_input_disp.set_state( inputs );
		}
		
		int old_dest = unit._destination_id;
		int new_dest = _command_ai.get_decision(inputs);//to!int(floor(uniform01!(float)() * NUM_CAPTURE_POINTS)); //TEMPTEMPTEMP
		
		if(old_dest != -1)
		{
			_unit_destination_counts[old_dest][unit._type]--;
		}
		
		_unit_destination_counts[new_dest][unit._type]++;
		
		
		return new_dest;
	}
	
	void record_move_order(Unit unit, int destination_index )
	{
		real[] inputs = get_command_inputs(unit);
		_command_ai.record_decision( inputs, destination_index );
	}
	
	
	UnitType get_build_order( FactoryUnit building_unit )
	{
		_num_builds++;
		
		real[] inputs = get_build_inputs(building_unit);
		
		
		return cast(UnitType)_build_ai.get_decision(inputs); //cast(UnitType)dice(18,18,18,3,3,3,1,1,1);
	}
	
	
	real[] get_build_inputs( FactoryUnit building_unit )
	{
		assert(_opponent !is null);
		
		/*real[] inputs = [ ];
		
		add_sigmoid_of_counts_to_array( 				_unit_counts				, &inputs );
		add_sigmoid_of_counts_to_array( 				_unit_destination_counts, &inputs );
		add_sigmoid_of_counts_to_array( _opponent._unit_counts  				, &inputs );
		add_sigmoid_of_counts_to_array( _opponent._unit_destination_counts, &inputs );
		foreach( point ; _points)
		{
			inputs ~= (point._team_id == _opponent._id ) ? 1.0 : 0.0;
			inputs ~= (point._team_id == TeamID.Neutral) ? 1.0 : 0.0;
		}
		inputs ~= _income           / _match_info._total_income_from_points;
		inputs ~= _opponent._income / _match_info._total_income_from_points;
		inputs ~= _game_timer / _match_info._timer_max;
		
		inputs ~= _tickets           / _match_info._tickets_max;  // g2.5
		inputs ~= _opponent._tickets / _match_info._tickets_max;  // g2.5
		
		
		//following are gen2 params
		
		foreach( point ; _points )
		{
			double dist = sqrt( square(building_unit._pos.x - point._pos.x) + square(building_unit._pos.y - point._pos.y) );
			inputs ~= dist / _match_info.battlefield_diagonal;
		}
			
		inputs ~= building_unit._health_current / building_unit._health_max;
		
		// following are gen2 params
		
		// location boredom
		inputs ~= always_positive_to_01( sigmoid(building_unit._location_boredom_timer) );
		
		// build boredom counter
		inputs ~= always_positive_to_01( sigmoid(building_unit._build_boredom_timer) );
		
		// num unit lost
		foreach(lost_count; _unit_lost_counts)
		{
			inputs ~= always_positive_to_01( sigmoid(lost_count) );
		}
		// num unit killed
		foreach(lost_count; _opponent._unit_lost_counts)
		{
			inputs ~= always_positive_to_01( sigmoid(lost_count) );
		}
		// num unit built
		foreach(built_count; _unit_built_counts)
		{
			inputs ~= always_positive_to_01( sigmoid(built_count) );
		}
		// num enemy unit built
		foreach(built_count; _opponent._unit_built_counts)
		{
			inputs ~= always_positive_to_01( sigmoid(built_count) );
		}
		// total unit cost at point
		foreach(total_cost; _unit_total_cost_at_points)
		{
			inputs ~= always_positive_to_01( sigmoid(total_cost) );
		}
		// enemy total cost at point
		foreach(total_cost; _opponent._unit_total_cost_at_points)
		{
			inputs ~= always_positive_to_01( sigmoid(total_cost) );
		}
		*/
		
		real[] inputs = get_common_ai_inputs(building_unit);
		
		// build boredom counter
		inputs ~= always_positive_to_01( sigmoid(building_unit._build_boredom_timer) );
		
		
		foreach (input; inputs)
		{
			assert(!isNaN(input), "garbage in!");
		}
		
		return inputs;
	}
	
	void record_build_decision(FactoryUnit building_unit, UnitType decision)
	{
		real[] inputs = get_build_inputs(building_unit);
		_build_ai.record_decision(inputs, decision);
	}
	

	void handle_endgame(bool won_game)
	{
		_game_over = true;
		if(won_game)
		{
			writefln("-----------%s Won!   %d orders, %d builds----------", _name, _num_orders_given, _num_builds);
			writeln("Training winner's build AI:");
			_build_ai.train_net(true);
			writeln("Training winner's command AI:");
			_command_ai.train_net(true);
			
			writeln("Training loser's build AI to emulate winner:");
			_opponent._build_ai.train_net_to_emulate(this._build_ai); 
			writeln("Training loser's command AI to emulate winner");
			_opponent._command_ai.train_net_to_emulate(this._command_ai);
		} else {
			writefln("-----------%s Lost!  %d orders, %d builds-----------", _name, _num_orders_given, _num_builds);
			writeln("Training loser's build AI:");
			_build_ai.train_net(false);
			writeln("Training loser's command AI:");
			_command_ai.train_net(false);
		}
		
		_build_ai  .save_net();
		_command_ai.save_net();
		
		// TODO: reset game state (from main?).
	}
	
	void notify_dead_factory()
	{
		_num_factories--;
		if( _num_factories == 0 ) 
		{
			/+
			handle_endgame(false); //you lose!
			_opponent.handle_endgame(true); // opponent wins!
			+/
		}
	}
	
	void cleanup_ais()
	{
		_build_ai  .cleanup();
		_command_ai.cleanup();
	}
	
	void set_ai_input_display(Vector2f display_location)
	{
		_input_disp = new NetworkInputDisplay( display_location, _color ); 
	}

}




void add_num_units_scaled_by_cost_to_array (int[][] count_array , real[]* neuron_input_array ) 
{
	foreach(location; count_array )
	{
		foreach( int type, count; location )
		{
			*neuron_input_array ~= num_units_scaled_by_cost( count, cast(UnitType) type );
		}
	}
}

const double UNIT_COST_SCALING_DIVISOR = get_unit_build_cost(UnitType.Battleship) * 10;

double num_units_scaled_by_cost(int unit_count, UnitType unit_type)
{
	return unit_count * get_unit_build_cost( unit_type ) / UNIT_COST_SCALING_DIVISOR;
}



void add_sigmoid_of_counts_to_array( int[][] count_array , real[]* neuron_input_array ) // 35 32.5 44 49 46   80085
{
	foreach(location; count_array )
		{
			foreach( count; location )
			{
				*neuron_input_array ~= always_positive_to_01(sigmoid( count ));
			}
		}
}

real always_positive_to_01(real input)
{
	return (input - 0.5) * 2.0;
}

