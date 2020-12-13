module team_scripted_boom;


import std.random;
import std.conv;
import std.stdio;
import std.format;

import team;
import ai_base;
import unit;
import factory_unit;
import collision;
import strategy;
import strategies;
import gamestateinfo;

import dsfml.graphics;
import dsfml.system;


// this team "booms" (focuses on building an economy).  Nothing to do with baby boomers.
class ScriptedBoomerTeam : TeamObj
{
  int _mush_orders = 0;
  static const int min_interceptors = 6; // start building interceptors when it has fewer than 6.  
  static const int max_interceptors = 9; // stops building them at 9
  bool _build_interceptors = true;
  int _num_builds = 0; // number of units built, not counting interceptors
  UnitType[] _build_queue;

  this(TeamID in_id, inout Color in_color, inout char[] in_name)
  {
    super( in_id, in_color, in_name, false);
	
	_build_queue.length = 10;
	_build_queue[0..6] = UnitType.Miner;
	_build_queue[6]    = UnitType.Cruiser;
	_build_queue[7]    = UnitType.Mothership;
	_build_queue[8..$] = UnitType.Destroyer;
  }
  
	override string generate_display_str()
	{
		return format("Scripted Boom AI");
	}

	override int assign_command(Unit unit)
	{ 
		
		int decision = unit._destination_id;
		UnitType type = unit._type;
		StateInfo gamestate = make_state_info(unit);
		const (Strategy)* strat;
		
		if (type == UnitType.Mothership)
		{
			if(_mush_orders < 4)
			{
				strat = &strat_capture_least_guarded;
			}
			else if(_mush_orders < 8)
			{
				strat = &strat_attack_weakest_enemy_force;
			}
			else
			{
				strat = &strat_stay_safe;
			}
			_mush_orders++;
		}
		if (type == UnitType.Interceptor)
		{
			strat = &strat_expand_safe;
		}
		if(type == UnitType.Miner)
		{
			strat = &strat_spread_out;
		}
		if(type == UnitType.Cruiser)
		{
			strat = &strat_guard_economy;
		}
		if(type == UnitType.Destroyer)
		{
			strat = &strat_attack_countered_units;
		}
		
		int strat_index = index_of_strat(*strat);
		assert(strat_index != -1);
		decision = (*strat).evaluate(gamestate);
		
		
		if (decision == -1) decision = unit._destination_id;
		if (decision == -1) decision = 0;
		
		int old_dest = unit._destination_id;
		int new_dest = decision;
		if(old_dest != -1)
		{
			_unit_destination_counts[old_dest][unit._type]--;
		}
		_unit_destination_counts[new_dest][unit._type]++;
		
		unit._last_strat = strat_index;
		record_move_order(unit, decision, strat_index); 
		return decision;
	}
	
	override UnitType get_build_order ( FactoryUnit building_unit )
	{
		UnitType decision;
		int num_interceptors = _total_units_by_type[UnitType.Interceptor];
		if (num_interceptors < min_interceptors)
			_build_interceptors = true;
		if (num_interceptors >= max_interceptors)
			_build_interceptors = false;
		if(_build_interceptors) 
			decision = UnitType.Interceptor;
			
		else 
		{
			decision = _build_queue[_num_builds % $];
			_num_builds++;
		}
		record_build_decision(building_unit, decision);
		return decision;
		
	}
	
	override void update( CollisionGrid grid, double dt )
	{
		/+_command_ai.load_or_initialize_net();
		_build_ai  .load_or_initialize_net();+/
  
    super.update(grid, dt);
  }
    

}