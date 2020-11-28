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
import std.format;

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
import nn_manager;
import nn_manager_classifier;
import matchinfo;
import gamestateinfo;

import dsfml.graphics;
import and.api;
import and.activation.model.iactivation;


enum TeamID {One, Two, Neutral}

const double INCOME_BASE = 20.0;
const double INCOME_PER_POINT = 20.0;


//Team object: responsible for maintaining the game state of one player's fleet, 
// providing an interface between the game state and the AI,
// and drawing UI elements related to the above.
// TODO: that is too many things for one object.
class TeamObj : Drawable
{
	double _income = 0.0;
	double _income_per_factory = 0.0;
	double _tickets = g_starting_tickets;
	
	Color  _color;
	
	TeamID _id;
	char[] _name;
	
	Font _font = null; 
	Text _display_str = null;
	
	TeamObj _opponent;
	
	FactoryUnit[]* _factories;
	CapturePoint[] _points; // list of all points.
	int[][]  _unit_counts;
	int[][]  _unit_destination_counts;
	double[] _unit_total_cost_at_points; // set by capture point objects
	int[]    _unit_built_counts;
	int[]    _unit_lost_counts;
	real     _total_army_value = 0.0; //TODO: this needs to be updated for the inital mothership. shuold there be a add_unit_to_team function?
	
	BaseAI _build_ai;//TODO: interface for build/ command ai?
	BaseAI _command_ai;
	
	int _num_factories    = 0;
	int _num_orders_given = 0;
	int _num_builds       = 0;
	int _num_points_owned = 0;
	
	double _game_timer = 0.0;
	bool   _game_over = false;
	
	bool _draw_NN_inputs;
	NetworkInputDisplay _input_disp;
	
	MatchInfo _match_info;
  
	bool _is_player_controlled = false;
  
	bool _train; // whether or not we train the NN at the end of each match.
	
	static const real TIME_SCALING_FACTOR = 30.0;
	
	IActivationFunction _build_act_fn;
	IActivationFunction _command_act_fn;
	
	
	this(TeamID in_id, inout Color in_color, inout char[] in_name, bool in_train = true, 
		IActivationFunction in_build_act_fn = null, IActivationFunction in_command_act_fn = null ) //TODO: will take AI objects.
	{
		_color = in_color;
		_id = in_id;
		_name = in_name.dup();
		_train = in_train;
		
		_unit_built_counts.length = NUM_UNIT_TYPES;
		_unit_lost_counts.length  = NUM_UNIT_TYPES;
		
		_build_act_fn = in_build_act_fn;
		_command_act_fn = in_command_act_fn;
		if (in_name != "")  //TODO: another neutral case
		{
			ensure_act_fns();
			init_ais(in_name);
		}
		//writefln("constructing team %s", in_name); //neutral team is made at compile time
		
	}
	
	//for constructor
	void init_ais(inout char[] in_name)
	{
		
		NNManagerBase build_nnm = new NNManagerClassifier(in_name ~ "_build.txt"    , _build_act_fn);
		_build_ai   = new BuildAI( build_nnm ); 
		
		
		NNManagerBase command_nnm = new NNManagerClassifier(in_name ~ "_command.txt", _command_act_fn);
		_command_ai = new CommandAI( command_nnm  );
		
	}
	
	// we assign default values here, so that not every subclass that wants to accept act_fns has to specify a default value in the ctor
	void ensure_act_fns()
	{
		if (_build_act_fn is null)
			_build_act_fn = new SigmoidActivationFunction();
		if (_command_act_fn is null)
			_command_act_fn = new SigmoidActivationFunction();
	}
	
	~this()
	{
		_factories = null; // this may avoid a memleak TODO: test this.
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
		
		if(_num_factories > 0)
		{
			_income_per_factory = _income / log2(_num_factories+1); // so Mothership spamming isn't overpowered
		} else {
			_income_per_factory = 0.0;
		}
		
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
		
		//TODO: gross, there should be a superclass of this that the neutral team is.
		if(_id != TeamID.Neutral)
			ensure_display_str(renderTarget).draw(renderTarget, renderStates);
			
			
		
	}
	
	Text ensure_display_str(RenderTarget renderTarget)
	{
		if(_display_str is null)
		{
			_display_str = new Text();
			//writeln(i, _points.length);
			_display_str.setFont(ensure_font()); 
			_display_str.setCharacterSize(15);
			_display_str.setColor(_color);
			
			Vector2!float offset = _id == TeamID.One ? Vector2!float(0.0, 0.0) : Vector2!float(renderTarget.getSize().x/2.0, 0.0);
			_display_str.position = Vector2!float(10.0, 35.0) + offset; 
			_display_str.position.x = to!int(_display_str.position.x);
			_display_str.position.y = to!int(_display_str.position.y);
		}
		_display_str.setString(generate_display_str());
		return _display_str;
	}
	
	Font ensure_font()
	{
		_font = new Font();
		if (!_font.loadFromFile("font/OpenSans-Regular.ttf"))
		{
			assert(false, "font didn't load");
		}
		return _font;
	}
	
	string generate_display_str()
	{
		return format("Classifier AI using %s", get_ai_actfn_name());
	}
	
	string get_ai_actfn_name()
	{
		return ActivationIdToStr(_command_ai._nn_mgr._activation_function.id);
	}
	
	// sets metric data for AIs
	void update_ai_records(double now)
	{
		int territory_diff = get_territory_diff();
		//real score = compute_partial_score(this) - compute_partial_score(_opponent); 
		//assert(!isNaN(score));
		real score = get_score_diff();
		_build_ai  .update_records(now, territory_diff, score);
		_command_ai.update_records(now, territory_diff, score);
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
		_unit_destination_counts.length   = _points.length;
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
	
	
	//gen 2  : num built/killed, location boredom, total cost at point
	//gen 2.5: tickets
	//gen 3  : fewer unit types,  point-is-neutral changed to pointed-not-owned-by-me
	//gen 3.5: closest point
	//gen 4  : Threat value at each point.
	real[] get_common_ai_inputs(Unit unit)
	{
		real[] inputs = [ ];
		inputs.reserve( NUM_UNIT_TYPES * NUM_CAPTURE_POINTS * 4 ); // so that we don't resize the array a bunch of times in the next 4 calls.
		
		//TODO: calculate the board state for the team externally, the first time it is needed each frame, and cache that shit.
		add_num_units_scaled_by_cost_to_array( 		       _unit_counts	 		   ,  inputs );
		add_num_units_scaled_by_cost_to_array( 		       _unit_destination_counts,  inputs );
		add_num_units_scaled_by_cost_to_array(   _opponent._unit_counts  		   ,  inputs );
		add_num_units_scaled_by_cost_to_array(   _opponent._unit_destination_counts,  inputs );
		//writefln("input size after unit counts: %d, expected value: %d, unittype has %d", inputs.length, NUM_UNIT_TYPES * NUM_CAPTURE_POINTS * 4, NUM_UNIT_TYPES);
		
		foreach( point ; _points)
		{
			inputs ~= (point._team_id == _opponent._id ) ? 1.0 : 0.0;
		}
		foreach( point ; _points)
		{
			inputs ~= (point._team_id != _id) ? 1.0 : 0.0;  //changed in gen 3,
		}
		
		inputs ~= _income           / _match_info._total_income_from_points;
		inputs ~= _opponent._income / _match_info._total_income_from_points;
		inputs ~= _game_timer / _match_info._timer_max;
		
		inputs ~= _tickets           / _match_info._tickets_max;  // g2.5
		inputs ~= _opponent._tickets / _match_info._tickets_max;  // g2.5
		
		//
		double closest_dist  = 9999.0;
		int    closest_point_index = -1;
		foreach( i, point ; _points )
		{
			double dist = sqrt( square(unit._pos.x - point._pos.x) + square(unit._pos.y - point._pos.y) );
			inputs ~= dist / _match_info._battlefield_diagonal;
			if(dist < closest_dist)
			{
				closest_dist = dist;
				closest_point_index = i;
			}
		}
		//closest point (gen3.5)
		foreach(i; 0.._points.length)
		{
			if(i == closest_point_index )
			{
				inputs ~= 1.0;
			} else {
				inputs ~= 0.0;
			}
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
		inputs ~= sigmoid(unit._location_boredom_timer  / TIME_SCALING_FACTOR);
		
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
			inputs ~= total_cost / UNIT_COST_SCALING_DIVISOR / 3.0;  //TODO: make this a constant like a sane person
		}
		// enemy total cost at point
		foreach(total_cost; _opponent._unit_total_cost_at_points)
		{
			inputs ~= total_cost / UNIT_COST_SCALING_DIVISOR / 3.0;
		}
		
		// threat for each point (gen 4)
		foreach( point ; _points )
		{
			inputs ~= point.getThreatDiffForTeam(_id) / UNIT_COST_SCALING_DIVISOR;
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
	
	StateInfo make_state_info(Unit unit)
	{
		return StateInfo(this, unit, _points, _match_info);
	}

	//TODO: make this more modular
	int assign_command(Unit unit)
	{
		_num_orders_given++;
		
		assert(_opponent !is null);
		
		real[] inputs = get_command_inputs(unit);
		
		if( _input_disp !is null && unit._type == UnitType.Mothership )
		{
			_input_disp.set_state( inputs );
		}
		
		int old_dest = unit._destination_id;
		DecisionResult result = _command_ai.get_decision(inputs, make_state_info(unit));
		int new_dest = result.decision;//to!int(floor(uniform01!(float)() * NUM_CAPTURE_POINTS)); //TEMPTEMPTEMP
		unit._last_strat = result.strategy;
		
		if (new_dest == -1)  //TODO: we could handle this case differently.
			new_dest = old_dest;
		if (new_dest == -1)
			new_dest = 0;
		
		if(old_dest != -1)
		{
			_unit_destination_counts[old_dest][unit._type]--;
		}
		
		_unit_destination_counts[new_dest][unit._type]++;
		
		
		return new_dest;
	}
	
	// used to record a move order when the player orders a move, 
	// orders are normally recorded in ai_base.get_decision() when the AI is queried for a decision.
	void record_move_order(Unit unit, int destination_index )
	{
		real[] inputs = get_command_inputs(unit);
		_command_ai.record_external_decision( inputs, destination_index );
	}
	
	
	UnitType get_build_order( FactoryUnit building_unit )
	{
		_num_builds++;
		
		real[] inputs = get_build_inputs(building_unit);
		
		
		return cast(UnitType)_build_ai.get_decision(inputs, make_state_info(building_unit)).decision; //cast(UnitType)dice(18,18,18,3,3,3,1,1,1);
	}
	
	
	real[] get_build_inputs( FactoryUnit building_unit )
	{
		assert(_opponent !is null);
		
		
		real[] inputs = get_common_ai_inputs(building_unit);
		
		// build boredom counter
		inputs ~= sigmoid(building_unit._build_boredom_timer / TIME_SCALING_FACTOR);
		
		
		foreach (input; inputs)
		{
			assert(!isNaN(input), "garbage in!");
		}
		
		return inputs;
	}
	
	
	// used to record a build command when the mothership builds a unit in a player controlled faction, (see record_move_decision)
	// orders are normally recorded in ai_base.get_decision() when the AI is queried for a decision.
	void record_build_decision(FactoryUnit building_unit, UnitType decision)
	{
		real[] inputs = get_build_inputs(building_unit);
		_build_ai.record_external_decision(inputs, decision);
	}
	

	void handle_endgame(bool won_game)
	{
		_game_over = true;
		
		//update records for all AIs, doing it twice won't cause any problems (because it uses queues for pending records)
		_build_ai  .update_records_endgame(won_game, get_territory_diff(), get_score_diff() );
		_command_ai.update_records_endgame(won_game, get_territory_diff(), get_score_diff() );
		
		_opponent._build_ai  .update_records_endgame(!won_game, -get_territory_diff(), -get_score_diff() );
		_opponent._command_ai.update_records_endgame(!won_game, -get_territory_diff(), -get_score_diff() );
		
		if(!_train)
		{
			return;
		}
		
		if(won_game)
		{
			writefln("-----------%s Won!   %d orders, %d builds----------", _name, _num_orders_given, _num_builds);
			//TODO: replace these prints with an overloadable function or two 
			//TODO: this should be generated by NNM
			write("Generating training set for winner's build AI: ");
			_build_ai  .make_training_data(_opponent._build_ai  );
			writefln("%s", _build_ai.get_training_header() );
			
			write("Generating training set for winner's command AI: ");
			_command_ai.make_training_data(_opponent._command_ai);
			writefln("%s", _command_ai.get_training_header());
			
			writefln("Training winner's build AI:");
			_build_ai  .train_net();
			writefln("Training winner's command AI:");
			_command_ai.train_net();
			
		} else {
			writefln("-----------%s Lost!  %d orders, %d builds-----------", _name, _num_orders_given, _num_builds);
			
			write("Generating training set for loser's build AI: ");
			_build_ai  .make_training_data(_opponent._build_ai  );
			writefln("%s", _build_ai.get_training_header() );
			
			write("Generating training set for loser's command AI: ");
			_command_ai.make_training_data(_opponent._command_ai);
			writefln("%s", _command_ai.get_training_header() );
			
			writefln("Training loser's build AI:");
			_build_ai  .train_net();
			writefln("Training loser's command AI:");
			_command_ai.train_net();
		}
		
		_build_ai  .save_net(); 
		_command_ai.save_net(); 
		
		
	}
	
	void notify_dead_factory()
	{
		_num_factories--;
		if( _num_factories == 0 ) 
		{
			/+  removed this as a victory condition
			handle_endgame(false); //you lose!
			_opponent.handle_endgame(true); // opponent wins!
			+/
		}
	}
	
	void cleanup_ais()
	{
		err.writeln(_build_ai);
		_build_ai  .cleanup();
		_command_ai.cleanup();
	}
	
	void set_ai_input_display(Vector2f display_location)
	{
		_input_disp = new NetworkInputDisplay( display_location, _color ); 
	}

	
	real get_score_diff()
	{
		real score = get_partial_score(this) - get_partial_score(_opponent);
		assert (!isNaN(score));
		if(score >  1.0){ score =  1.0; }
		if(score < -1.0){ score = -1.0; }
		return score;
	}
	
	int get_territory_diff()
	{
		return _num_points_owned - _opponent._num_points_owned;
	}
}




void add_num_units_scaled_by_cost_to_array (int[][] count_array , ref real[] neuron_input_array ) 
{
	foreach(ref location; count_array )
	{
		foreach( int type, ref count; location )
		{
			neuron_input_array ~= num_units_scaled_by_cost( count, cast(UnitType) type );
		}
	}
}

const real UNIT_COST_SCALING_DIVISOR = get_unit_build_cost(UnitType.Battleship) * 10;

real num_units_scaled_by_cost(int unit_count, UnitType unit_type)
{
	return unit_count * get_unit_build_cost( unit_type ) / UNIT_COST_SCALING_DIVISOR;
}


deprecated void add_sigmoid_of_counts_to_array( int[][] count_array , real[]* neuron_input_array ) 
{
	foreach(location; count_array )
		{
			foreach( count; location )
			{
				*neuron_input_array ~= always_positive_to_01(sigmoid( count ));
			}
		}
}

//TODO: could replace this with smarter use of sigmoid function
real always_positive_to_01(real input)
{
	return (input - 0.5) * 2.0;
}



// computes a score in the approximate range [-1.0, 1.0] It can go a bit over or under because we use ReLUs in the AI (which are not bound to that range)
// the opponent's score should be subtracted from this TODO: rename this function
real get_partial_score(TeamObj t)
{
	// each metric is divided by a reasonable maxiumum
	/* 	  1/3 * points_capped/12 points 
		+ 1/3 * income / (income form 12 points + default income + 1 miner at each point)
		+ 1/3 * army strength / 20 battleships
	*/
	//writefln("pts: %d, income: %f * %d, army: %f", t._num_points_owned, t._income_per_factory, t._num_factories, t._total_army_value);
	assert(!isNaN(t._income_per_factory), "income is NaN" );
	assert(!isNaN(t._total_army_value)  , "army is NaN" );
	real retval = 1.0/3.0 * t._num_points_owned / NUM_CAPTURE_POINTS
				+ 1.0/3.0 * t._income_per_factory * t._num_factories / (INCOME_BASE + INCOME_PER_POINT * NUM_CAPTURE_POINTS + INCOME_PER_POINT * TeamObj.MINER_INCOME_FRACTION * NUM_CAPTURE_POINTS )
				+ 1.0/3.0 * t._total_army_value / (get_unit_build_cost(UnitType.Battleship) * 20) ;
				
	return retval;
}

