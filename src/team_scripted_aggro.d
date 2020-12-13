module team_scripted_aggro;


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


// this team expands with Interceptors early, tries to kill some capping units with its Mothership,
// then spams Battleships.
class ScriptedAggroTeam : TeamObj
{
  int _mush_orders = 0;

  this(TeamID in_id, inout Color in_color, inout char[] in_name)
  {
    super( in_id, in_color, in_name, false);
  }
  
  override string generate_display_str()
	{
		return format("Scripted Aggro AI");
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
		if(type == UnitType.Battleship)
		{
			strat = &strat_kite_and_snipe;
		}
		
		int strat_index = index_of_strat(*strat);
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
		UnitType decision = _total_units_by_type[UnitType.Interceptor] < 6 ? UnitType.Interceptor : UnitType.Battleship;
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