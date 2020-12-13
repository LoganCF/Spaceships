module team_scripted_capper2;


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

class ScriptedCapper2Team : TeamObj
{

  this(TeamID in_id, inout Color in_color, inout char[] in_name)
  {
    super( in_id, in_color, in_name, false);
  }
  
  override string generate_display_str()
	{
		return format("Scripted Capper AI Mk2");
	}

	override int assign_command(Unit unit)
	{ 
		/+_command_ai.load_or_initialize_net();+/

		int decision = unit._destination_id;
		
		StateInfo gamestate = make_state_info(unit);
		
		decision = strat_expand_safe.evaluate(gamestate);
		
		
		if (decision == -1) decision = unit._destination_id;
		if (decision == -1) decision = 0;
		
		int old_dest = unit._destination_id;
		int new_dest = decision;
		if(old_dest != -1)
		{
			_unit_destination_counts[old_dest][unit._type]--;
		}
		_unit_destination_counts[new_dest][unit._type]++;
		
		int strat_id = index_of_strat(strat_expand_safe);
		unit._last_strat = strat_id;
		
		record_move_order(unit, decision, strat_id);
		return decision;
	}
	
	override UnitType get_build_order ( FactoryUnit building_unit )
	{
		
		
		UnitType decision = _income < 200.0 ? UnitType.Interceptor : UnitType.Battleship;
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